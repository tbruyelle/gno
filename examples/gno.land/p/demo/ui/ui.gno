package ui

import (
	"strconv"
	"strings"

	"gno.land/p/demo/avl"
)

type DOM struct {
	// metadata
	Prefix string
	Title  string

	// elements
	Header Element
	Body   Element
	Footer Element
}

func (dom DOM) String() string {
	output := ""

	if dom.Title != "" {
		output += H1(dom.Title).String() + "\n"
	}

	if !dom.Header.Empty() {
		output += dom.Header.Content + "\n"
	}

	if !dom.Body.Empty() {
		output += dom.Body.Content + "\n"
	}

	if !dom.Footer.Empty() {
		output += dom.Footer.Content + "\n"
	}

	// TODO: cleanup double new-lines.

	return output
}

type Element struct {
	Content string
}

func (e Element) Empty() bool {
	return e.Content == ""
}

func (e *Element) Append(elems ...stringer) {
	for _, elem := range elems {
		e.Content += elem.String() + "\n"
	}
}

func Breadcrumb(entries ...stringer) stringer {
	output := ""
	for idx, entry := range entries {
		if idx > 0 {
			output += " / "
		}
		output += entry.String()
	}
	return Raw{Content: output}
}

type Link struct {
	Text string
	Path string
	URL  string
}

// TODO: image

// TODO: pager

func (l Link) String() string {
	// TODO: additional arguments.
	if l.Path != "" && l.URL != "" {
		panic("a link should have a path OR a URL.")
	}

	if l.Path != "" {
		// TODO: prefix
		l.URL = "prefix" + l.Path
	}
	return "[" + l.Text + "](" + l.URL + ")"
}

func Paragraph(s string) stringer {
	return Raw{Content: "\n" + s + "\n"}
}

func BulletList(entries ...stringer) stringer {
	output := ""

	for _, entry := range entries {
		output += "- " + entry.String() + "\n"
	}

	return Raw{Content: output}
}

func Text(s string) stringer {
	return Raw{Content: s}
}

type stringer interface {
	String() string
}

type Raw struct {
	Content string
}

func (r Raw) String() string {
	return r.Content
}

func H1(text string) stringer     { return Raw{Content: "# " + text + "\n"} }
func H2(text string) stringer     { return Raw{Content: "## " + text + "\n"} }
func H3(text string) stringer     { return Raw{Content: "### " + text + "\n"} }
func H4(text string) stringer     { return Raw{Content: "#### " + text + "\n"} }
func H5(text string) stringer     { return Raw{Content: "##### " + text + "\n"} }
func H6(text string) stringer     { return Raw{Content: "###### " + text + "\n"} }
func Bold(text string) stringer   { return Raw{Content: "**" + text + "**"} }
func Italic(text string) stringer { return Raw{Content: "_" + text + "_"} }
func Code(text string) stringer   { return Raw{Content: "`" + text + "`"} }
func HR() stringer                { return Raw{Content: "\n---\n"} }

// Extension represents a custom markdown wrapped between `:::`.
type Extension struct {
	Name    string
	Content Element
}

func (e Extension) String() string {
	return ":::" + e.Name + "\n" + e.Content.Content + ":::\n"
}

func Jumbotron(content ...stringer) stringer {
	j := Extension{
		Name: "jumbotron",
	}
	for _, c := range content {
		j.Content.Append(c)
	}
	return j
}

func Paginate(offset, limit int, tree *avl.Tree, urlFormat func(p int) string) stringer {
	var items []stringer
	tree.IterateByOffset(offset, limit, func(n *avl.Node) bool {
		items = append(items, n.Value().(stringer))
		return true
	})
	list := BulletList(items...)
	pagination := Pagination(offset, limit, tree.Size(), urlFormat)
	return Raw{list.String() + "\n\n" + pagination.String()}
}

func Pagination(offset, limit, total int, urlFormat func(page int) string) stringer {
	if limit <= 0 {
		panic("Pagination: limit must be positive")
	}
	if total == 0 {
		// return nothing if there's no item
		return Raw{}
	}
	var (
		currentPage = offset/limit + 1
		prevPage    = currentPage - 1
		nextPage    = currentPage + 1
		totalPages  = (total + limit - 1) / limit
		content     = "Pages "
	)
	if prevPage >= 1 {
		content += "[<](" + urlFormat(prevPage) + ")"
	} else {
		content += "<"
	}
	content += "|"

	for i := 1; i <= totalPages; i++ {
		switch i {
		case currentPage:
			content += "**" + strconv.Itoa(i) + "**|"
		case 1, 2, currentPage - 1, currentPage, currentPage + 1, totalPages - 1, totalPages:
			content += "[" + strconv.Itoa(i) + "](" + urlFormat(i) + ")|"
		default:
			if !strings.HasSuffix(content, "...|") {
				content += "...|"
			}
			// if pages[len(pages)-1] != -1 {
			// pages = append(pages, -1)
			// }
		}
	}
	if nextPage <= totalPages {
		content += "[>](" + urlFormat(nextPage) + ")"
	} else {
		content += ">"
	}
	return Raw{content}
}
