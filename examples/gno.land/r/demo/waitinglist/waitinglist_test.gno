package waitinglist

import (
	"std"
	"testing"

	"gno.land/p/demo/ufmt"
)

func TestCreateList(t *testing.T) {
	user := std.Address("g1us8428u2a5satrlxzagqqa5m6vmuze025anjlj")
	std.TestSetOrigCaller(user)

	id := CreateList("list1", "desc1")

	if id != 1 {
		t.Fatalf("invalid id expected 1 got %d", id)
	}
	expectedRender := ufmt.Sprintf("1 list1 %s 0\n", user.String())
	if render := Render(""); render != expectedRender {
		t.Fatalf("invalid Render, expected\n%s\ngot\n%s", expectedRender, render)
	}

	id = CreateList("list2", "desc2")

	if id != 2 {
		t.Fatalf("invalid id expected 2 got %d", id)
	}
	expectedRender = ufmt.Sprintf("1 list1 %s 0\n2 list2 %s 0\n", user.String(), user.String())
	if render := Render(""); render != expectedRender {
		t.Fatalf("invalid Render, expected\n%s\ngot\n%s", expectedRender, render)
	}
}

func TestSubscribeList(t *testing.T) {
	user := std.Address("g1us8428u2a5satrlxzagqqa5m6vmuze025anjlj")
	std.TestSetOrigCaller(user)
	id := CreateList("list42", "")

	SubscribeList(id)

	expectedRender := ufmt.Sprintf("%s list42 %s 1\n", id.String(), user.String())
	if render := Render(id.String()); render != expectedRender {
		t.Fatalf("invalid Render, expected\n%s\ngot\n%s", expectedRender, render)
	}

	defer func() {
		err := recover()
		if err.(string) != "already subscribed" {
			t.Errorf("expected panic because already subscribed")
		}
	}()
	SubscribeList(id)
}
