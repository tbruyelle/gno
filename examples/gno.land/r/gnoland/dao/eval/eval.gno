package eval

import (
	"std"
	"strconv"
	"time"

	"gno.land/p/demo/avl"
)

type id uint64

func (id id) String() string {
	return strconv.Itoa(int(id))
}

var (
	contribs   avl.Tree
	contribCtr id
)

type contrib struct {
	id      id
	creator std.Address
	time    time.Time
	name    string
	body    string
}

func CreateContrib(name, body string) id {
	std.AssertOriginCall()
	contribCtr++
	c := contrib{
		id:      contribCtr,
		creator: std.GetOrigCaller(),
		name:    name,
		body:    body,
	}
	contribs.Set(c.id.String(), c)
	return c.id
}

func Render(path string) string {
	return `!!! info

Hello world

!!!`
}
