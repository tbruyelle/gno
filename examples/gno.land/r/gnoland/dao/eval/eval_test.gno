package eval

import (
	"std"
	"testing"
)

func TestCreateContrib(t *testing.T) {
	std.TestSetOrigCaller(std.Address("g1u7y667z64x2h7vc6fmpcprgey4ck233jaww9zq"))
	// author := std.GetOrigCaller()

	id := CreateContrib("name", "body")

	println(id.String(), contribs)
}
