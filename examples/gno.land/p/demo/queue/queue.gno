package queue

type Queue struct {
	first  *node
	last   *node
	length int
}

type node struct {
	val  interface{}
	next *node
}

func New() *Queue {
	return &Queue{}
}

func (q *Queue) Push(x interface{}) {
	q.length++
	if q.first == nil {
		q.first = &node{val: x}
		q.last = q.first
		return
	}
	q.last.next = &node{val: x}
	q.last = q.last.next
}

func (q *Queue) Pop() interface{} {
	if q.first == nil {
		return nil
	}
	q.length--
	first := q.first
	q.first = first.next
	if q.first == nil {
		q.last = nil
	}
	return first.val
}

func (q Queue) Length() int {
	return q.length
}
