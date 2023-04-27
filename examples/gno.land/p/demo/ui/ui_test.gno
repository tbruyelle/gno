package ui

import (
	"testing"
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
