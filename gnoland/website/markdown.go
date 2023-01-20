package main

import (
	"bytes"
	"fmt"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/renderer"
	"github.com/yuin/goldmark/util"
)

type Attribute struct {
	Key, Val string
}
type Attributes []Attribute

func (a Attributes) Get(key string) (string, bool) {
	for i := 0; i < len(a); i++ {
		if a[i].Key == key {
			return a[i].Val, true
		}
	}
	return "", false
}

func ParseAttributes(bz []byte) (attrs Attributes) {
	for _, bz := range bytes.Fields(bz) {
		bzs := bytes.Split(bz, []byte{'='})
		if len(bzs) > 1 {
			attrs = append(attrs, Attribute{
				Key: string(bzs[0]),
				Val: string(bytes.Trim(bzs[1], `"`)),
			})
		}
	}
	return
}

// fencedBlockHTMLRenderer overrides the defaults FencedCodeBlock renderer
type fencedBlockHTMLRenderer struct{}

func (r *fencedBlockHTMLRenderer) RegisterFuncs(reg renderer.NodeRendererFuncRegisterer) {
	reg.Register(ast.KindFencedCodeBlock, r.render)
}

func (r *fencedBlockHTMLRenderer) render(w util.BufWriter, source []byte, n ast.Node, entering bool) (ast.WalkStatus, error) {
	if entering {
		var (
			n      = n.(*ast.FencedCodeBlock)
			lang   = n.Language(source)
			attrBz = bytes.TrimPrefix(n.Info.Text(source), lang)
			attrs  = ParseAttributes(attrBz)
			typ, _ = attrs.Get("type")
		)
		switch typ {

		case "form":
			fmt.Fprintf(w, "<h1>CUSTOM %s</h1>", lang)

		default:
			goldmark.DefaultRenderer().Render(w, source, n)
		}
	}
	return ast.WalkContinue, nil
}
