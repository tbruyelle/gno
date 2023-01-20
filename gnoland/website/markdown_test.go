package main

import (
	"fmt"
	"testing"

	"github.com/jaekwon/testify/assert"
)

func TestParseAttributes(t *testing.T) {
	tests := []struct {
		name     string
		input    []byte
		expected Attributes
	}{
		{
			name:     "empty input",
			input:    nil,
			expected: nil,
		},
		{
			name:     "no attributes",
			input:    []byte("no attributes"),
			expected: nil,
		},
		{
			name:  "some attributes",
			input: []byte(`type="form" xxx style=shiny`),
			expected: Attributes{
				{"type", "form"},
				{"style", "shiny"},
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			attrs := ParseAttributes(tt.input)

			assert.Equal(t, tt.expected, attrs)
			for _, a := range tt.expected {
				v, ok := attrs.Get(a.Key)
				assert.True(t, ok)
				assert.Equal(t, a.Val, v)
			}
			v, ok := attrs.Get("xxx")
			assert.False(t, ok)
			assert.Empty(t, v)
		})
	}
}

func TestFencedCodeBlock(t *testing.T) {
	source := []byte("# hello world\n" +
		"```js\n" +
		"javascript\n" +
		"```\n" +
		"```json type=\"form\"\n" +
		"{\"foo\":1}\n" +
		"```\n")
	fmt.Println(mustMarkdownConvert(source))
}
