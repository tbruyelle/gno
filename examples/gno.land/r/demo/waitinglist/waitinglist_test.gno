package waitinglist

import (
	"std"
	"testing"
)

func TestCreateList(t *testing.T) {
	user := std.Address("g1us8428u2a5satrlxzagqqa5m6vmuze025anjlj")
	std.TestSetOrigCaller(user)

	id := CreateList("title", "desc")

	println("new list", id.String())
	println(Render(""))

	SubscribeList(id)

	println(Render(""))
}
