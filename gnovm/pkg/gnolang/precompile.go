package gnolang

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	goscanner "go/scanner"
	"go/token"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"go.uber.org/multierr"
	"golang.org/x/tools/go/ast/astutil"

	"github.com/gnolang/gno/tm2/pkg/std"
)

const (
	GnoRealmPkgsPrefixBefore = "gno.land/r/"
	GnoRealmPkgsPrefixAfter  = "github.com/gnolang/gno/examples/gno.land/r/"
	GnoPackagePrefixBefore   = "gno.land/p/demo/"
	GnoPackagePrefixAfter    = "github.com/gnolang/gno/examples/gno.land/p/demo/"
	GnoStdPkgBefore          = "std"
	GnoStdPkgAfter           = "github.com/gnolang/gno/gnovm/stdlibs/stdshim"
)

var stdlibWhitelist = []string{
	// go
	"bufio",
	"bytes",
	"compress/gzip",
	"context",
	"crypto/md5",
	"crypto/sha1",
	"crypto/chacha20",
	"crypto/cipher",
	"crypto/sha256",
	"encoding/base64",
	"encoding/binary",
	"encoding/hex",
	"encoding/json",
	"encoding/xml",
	"errors",
	"hash",
	"hash/adler32",
	"internal/bytealg",
	"internal/os",
	"flag",
	"fmt",
	"io",
	"io/util",
	"math",
	"math/big",
	"math/bits",
	"math/rand",
	"net/url",
	"path",
	"regexp",
	"sort",
	"strconv",
	"strings",
	"text/template",
	"time",
	"unicode",
	"unicode/utf8",

	// gno
	"std",
}

var importPrefixWhitelist = []string{
	"github.com/gnolang/gno/_test",
}

const ImportPrefix = "github.com/gnolang/gno"

type precompileResult struct {
	Imports    []*ast.ImportSpec
	Translated string
}

// TODO: func PrecompileFile: supports caching.
// TODO: func PrecompilePkg: supports directories.

func guessRootDir(fileOrPkg string, goBinary string) (string, error) {
	abs, err := filepath.Abs(fileOrPkg)
	if err != nil {
		return "", err
	}
	args := []string{"list", "-m", "-mod=mod", "-f", "{{.Dir}}", ImportPrefix}
	cmd := exec.Command(goBinary, args...)
	cmd.Dir = abs
	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("can't guess --root-dir")
	}
	rootDir := strings.TrimSpace(string(out))
	return rootDir, nil
}

// GetPrecompileFilenameAndTags returns the filename and tags for precompiled files.
func GetPrecompileFilenameAndTags(gnoFilePath string) (targetFilename, tags string) {
	nameNoExtension := strings.TrimSuffix(filepath.Base(gnoFilePath), ".gno")
	switch {
	case strings.HasSuffix(gnoFilePath, "_filetest.gno"):
		tags = "gno && filetest"
		targetFilename = "." + nameNoExtension + ".gno.gen.go"
	case strings.HasSuffix(gnoFilePath, "_test.gno"):
		tags = "gno && test"
		targetFilename = "." + nameNoExtension + ".gno.gen_test.go"
	default:
		tags = "gno"
		targetFilename = nameNoExtension + ".gno.gen.go"
	}
	return
}

func PrecompileAndCheckMempkg(mempkg *std.MemPackage) error {
	gofmt := "gofmt"

	tmpDir, err := os.MkdirTemp("", mempkg.Name)
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmpDir) //nolint: errcheck

	var errs error
	for _, mfile := range mempkg.Files {
		if !strings.HasSuffix(mfile.Name, ".gno") {
			continue // skip spurious file.
		}
		res, err := Precompile(mfile.Body, "gno,tmp", mfile.Name)
		if err != nil {
			errs = multierr.Append(errs, err)
			continue
		}
		tmpFile := filepath.Join(tmpDir, mfile.Name)
		err = os.WriteFile(tmpFile, []byte(res.Translated), 0o644)
		if err != nil {
			errs = multierr.Append(errs, err)
			continue
		}
		err = PrecompileVerifyFile(tmpFile, gofmt)
		if err != nil {
			errs = multierr.Append(errs, err)
			continue
		}
	}

	if errs != nil {
		return fmt.Errorf("precompile package: %w", errs)
	}
	return nil
}

func Precompile(source string, tags string, filename string) (*precompileResult, error) {
	fset := token.NewFileSet()
	f, err := parser.ParseFile(fset, filename, source, parser.ParseComments)
	if err != nil {
		return nil, fmt.Errorf("parse: %w", err)
	}

	isTestFile := strings.HasSuffix(filename, "_test.gno") || strings.HasSuffix(filename, "_filetest.gno")
	shouldCheckWhitelist := !isTestFile

	transformed, err := precompileAST(fset, f, shouldCheckWhitelist)
	if err != nil {
		return nil, fmt.Errorf("precompileAST: %w", err)
	}

	var out bytes.Buffer
	// Write file header
	out.WriteString("// Code generated by github.com/gnolang/gno. DO NOT EDIT.\n\n")
	if tags != "" {
		fmt.Fprintf(&out, "//go:build %s\n\n", tags)
	}
	// Add a //line directive so the go compiler outputs file's position that
	// corresponds to the initial gno file's position.
	// See https://pkg.go.dev/cmd/compile#hdr-Compiler_Directives
	out.WriteString("//line :1:1\n")

	// Write file content and format it.
	err = format.Node(&out, fset, transformed)
	if err != nil {
		return nil, fmt.Errorf("format.Node: %w", err)
	}

	res := &precompileResult{
		Imports:    f.Imports,
		Translated: out.String(),
	}
	return res, nil
}

// PrecompileVerifyFile tries to run `go fmt` against a precompiled .go file.
//
// This is fast and won't look the imports.
func PrecompileVerifyFile(path string, gofmtBinary string) error {
	// TODO: use cmd/parser instead of exec?

	args := strings.Split(gofmtBinary, " ")
	args = append(args, []string{"-l", "-e", path}...)
	cmd := exec.Command(args[0], args[1:]...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Fprintln(os.Stderr, string(out))
		return fmt.Errorf("%s: %w", gofmtBinary, err)
	}
	return nil
}

// PrecompileBuildPackage tries to run `go build` against the precompiled .go files.
//
// This method is the most efficient to detect errors but requires that
// all the import are valid and available.
func PrecompileBuildPackage(fileOrPkg, goBinary string) error {
	// TODO: use cmd/compile instead of exec?
	// TODO: find the nearest go.mod file, chdir in the same folder, rim prefix?
	// TODO: temporarily create an in-memory go.mod or disable go modules for gno?
	// TODO: ignore .go files that were not generated from gno?
	// TODO: automatically precompile if not yet done.

	files := []string{}

	info, err := os.Stat(fileOrPkg)
	if err != nil {
		return fmt.Errorf("invalid file or package path %s: %w", fileOrPkg, err)
	}
	if !info.IsDir() {
		file := fileOrPkg
		files = append(files, file)
	} else {
		pkgDir := fileOrPkg
		goGlob := filepath.Join(pkgDir, "*.go")
		goMatches, err := filepath.Glob(goGlob)
		if err != nil {
			return fmt.Errorf("glob %s: %w", goGlob, err)
		}
		for _, goMatch := range goMatches {
			switch {
			case strings.HasPrefix(goMatch, "."): // skip
			case strings.HasSuffix(goMatch, "_filetest.go"): // skip
			case strings.HasSuffix(goMatch, "_filetest.gno.gen.go"): // skip
			case strings.HasSuffix(goMatch, "_test.go"): // skip
			case strings.HasSuffix(goMatch, "_test.gno.gen.go"): // skip
			default:
				files = append(files, goMatch)
			}
		}
	}

	sort.Strings(files)
	args := append([]string{"build", "-v", "-tags=gno"}, files...)
	cmd := exec.Command(goBinary, args...)
	rootDir, err := guessRootDir(fileOrPkg, goBinary)
	if err == nil {
		cmd.Dir = rootDir
	}
	out, err := cmd.CombinedOutput()
	if _, ok := err.(*exec.ExitError); ok {
		// exit error
		return parseGoBuildErrors(string(out))
	}
	return err
}

var errorRe = regexp.MustCompile(`(?m)^(\S+):(\d+):(\d+): (.+)$`)

// parseGoBuildErrors returns a scanner.ErrorList filled with all errors found
// in out, which is supposed to be the output of the `go build` command.
// Each errors are translated into their correlated gno files by changing their
// filenames from `*.gno.gen.go` to `*.gno`.
//
// TODO(tb): update when `go build -json` is released to replace regexp usage.
// See https://github.com/golang/go/issues/62067
func parseGoBuildErrors(out string) error {
	var errList goscanner.ErrorList
	matches := errorRe.FindAllStringSubmatch(out, -1)
	for _, match := range matches {
		filename := match[1]
		line, err := strconv.Atoi(match[2])
		if err != nil {
			return fmt.Errorf("parse line go build error %s: %w", match, err)
		}

		column, err := strconv.Atoi(match[3])
		if err != nil {
			return fmt.Errorf("parse column go build error %s: %w", match, err)
		}
		msg := match[4]
		errList.Add(token.Position{
			// Remove .gen.go extension, we want to target the gno file
			Filename: strings.TrimSuffix(filename, ".gen.go"),
			Line:     line,
			Column:   column,
		}, msg)
	}
	return errList.Err()
}

func precompileAST(fset *token.FileSet, f *ast.File, checkWhitelist bool) (ast.Node, error) {
	var errs goscanner.ErrorList

	imports := astutil.Imports(fset, f)

	// import whitelist
	if checkWhitelist {
		for _, paragraph := range imports {
			for _, importSpec := range paragraph {
				importPath := strings.TrimPrefix(strings.TrimSuffix(importSpec.Path.Value, `"`), `"`)

				if strings.HasPrefix(importPath, GnoRealmPkgsPrefixBefore) {
					continue
				}

				if strings.HasPrefix(importPath, GnoPackagePrefixBefore) {
					continue
				}

				valid := false
				for _, whitelisted := range stdlibWhitelist {
					if importPath == whitelisted {
						valid = true
						break
					}
				}
				if valid {
					continue
				}

				for _, whitelisted := range importPrefixWhitelist {
					if strings.HasPrefix(importPath, whitelisted) {
						valid = true
						break
					}
				}
				if valid {
					continue
				}

				errs.Add(fset.Position(importSpec.Pos()), fmt.Sprintf("import %q is not in the whitelist", importPath))
			}
		}
	}

	// rewrite imports
	for _, paragraph := range imports {
		for _, importSpec := range paragraph {
			importPath := strings.TrimPrefix(strings.TrimSuffix(importSpec.Path.Value, `"`), `"`)

			// std package
			if importPath == GnoStdPkgBefore {
				if !astutil.RewriteImport(fset, f, GnoStdPkgBefore, GnoStdPkgAfter) {
					errs.Add(fset.Position(importSpec.Pos()), fmt.Sprintf("failed to replace the %q package with %q", GnoStdPkgBefore, GnoStdPkgAfter))
				}
			}

			// p/pkg packages
			if strings.HasPrefix(importPath, GnoPackagePrefixBefore) {
				target := GnoPackagePrefixAfter + strings.TrimPrefix(importPath, GnoPackagePrefixBefore)

				if !astutil.RewriteImport(fset, f, importPath, target) {
					errs.Add(fset.Position(importSpec.Pos()), fmt.Sprintf("failed to replace the %q package with %q", importPath, target))
				}
			}

			// r/realm packages
			if strings.HasPrefix(importPath, GnoRealmPkgsPrefixBefore) {
				target := GnoRealmPkgsPrefixAfter + strings.TrimPrefix(importPath, GnoRealmPkgsPrefixBefore)

				if !astutil.RewriteImport(fset, f, importPath, target) {
					errs.Add(fset.Position(importSpec.Pos()), fmt.Sprintf("failed to replace the %q package with %q", importPath, target))
				}
			}
		}
	}

	// custom handler
	node := astutil.Apply(f,
		// pre
		func(c *astutil.Cursor) bool {
			// do things here
			return true
		},
		// post
		func(c *astutil.Cursor) bool {
			// and here
			return true
		},
	)
	return node, errs.Err()
}
