package ui

import (
	"testing"

	"gno.land/p/demo/ufmt"
)

func TestJumbotron(t *testing.T) {
	j := Jumbotron(
		H1("Hello Jumbo"),
		Text("This is a jumbotron, a markdown extension"),
	)

	want := `:::jumbotron
# Hello Jumbo

This is a jumbotron, a markdown extension
:::
`
	got := j.String()
	if got != want {
		t.Errorf("want=%s, got=%s", want, got)
	}
}

func TestPagination(t *testing.T) {
	tests := []struct {
		offset, limit, total int
		expect               string
	}{
		{
			limit:  30,
			expect: "",
		},
		{
			offset: 0,
			limit:  30,
			total:  60,
			expect: "Pages <|**1**|[2](page=2)|[>](page=2)",
		},
		{
			offset: 29,
			limit:  30,
			total:  60,
			expect: "Pages <|**1**|[2](page=2)|[>](page=2)",
		},
		{
			offset: 30,
			limit:  30,
			total:  60,
			expect: "Pages [<](page=1)|[1](page=1)|**2**|>",
		},
		{
			offset: 30,
			limit:  10,
			total:  60,
			expect: "Pages [<](page=3)|[1](page=1)|[2](page=2)|[3](page=3)|**4**|[5](page=5)|[6](page=6)|[>](page=5)",
		},
		{
			offset: 60,
			limit:  10,
			total:  600,
			expect: "Pages [<](page=6)|[1](page=1)|[2](page=2)|...|[6](page=6)|**7**|[8](page=8)|...|[59](page=59)|[60](page=60)|[>](page=8)",
		},
	}
	for _, tt := range tests {
		t.Run(ufmt.Sprintf("offset=%d limit=%d total=%d", tt.offset, tt.limit, tt.total), func(t *testing.T) {
			res := Pagination(tt.offset, tt.limit, tt.total, func(p int) string {
				return ufmt.Sprintf("page=%d", p)
			})

			if got := res.String(); got != tt.expect {
				t.Errorf("want=%s\ngot=%s", tt.expect, got)
			}
		})
	}
}
