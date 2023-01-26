package main

import (
	"std"
	"testing"

	"gno.land/r/gnoland/dao/eval"
)

func main() {
	// std.TestSetOrigCaller(std.Address("g1u7y667z64x2h7vc6fmpcprgey4ck233jaww9zq"))
	// author := std.GetOrigCaller()

	id := eval.CreateContrib("name", "body")

	println("createContrib:", id.String())

	println(eval.Render(""))
}

// Output:
// createContrib: 1
// !!! info
//
// Hello world
//
// !!!
