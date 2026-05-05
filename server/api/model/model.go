package model

import "errors"

// TaskType is the kind of work a task represents.
type TaskType string

const (
	TaskTypeFeature TaskType = "feature"
	TaskTypeBug     TaskType = "bug"
)

func (t TaskType) Valid() bool {
	switch t {
	case TaskTypeFeature, TaskTypeBug:
		return true
	}
	return false
}

// TaskState is the current position in the workflow.
type TaskState string

const (
	StateCreated TaskState = "created"
	StateDesign  TaskState = "design"
	StateDev     TaskState = "dev"
	StateTest    TaskState = "test"
	StateReview  TaskState = "review"
	StateDone    TaskState = "done"
)

// stateOrder reflects the canonical workflow position. A task may move forward
// (skipping intermediate stages is allowed) but never backward.
var stateOrder = map[TaskState]int{
	StateCreated: 0,
	StateDesign:  1,
	StateDev:     2,
	StateTest:    3,
	StateReview:  4,
	StateDone:    5,
}

func (s TaskState) Valid() bool {
	_, ok := stateOrder[s]
	return ok
}

// CanTransitionTo returns nil if moving from s to next is allowed.
func (s TaskState) CanTransitionTo(next TaskState) error {
	if !s.Valid() {
		return errors.New("invalid current state")
	}
	if !next.Valid() {
		return errors.New("invalid next state")
	}
	if stateOrder[next] < stateOrder[s] {
		return errors.New("cannot move task state backward")
	}
	return nil
}

// IsTerminal reports whether the task is in its final state.
func (s TaskState) IsTerminal() bool { return s == StateDone }

// Project is a workspace that owns tasks.
type Project struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	CreatedAt   int64  `json:"created_at"`
	UpdatedAt   int64  `json:"updated_at"`
}

// Task is the unit of work tracked under a project.
type Task struct {
	ID          string    `json:"id"`
	ProjectID   string    `json:"project_id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Type        TaskType  `json:"type"`
	State       TaskState `json:"state"`
	Priority    int       `json:"priority"`
	DependsOn   []string  `json:"depends_on,omitempty"`
	Images      []Image   `json:"images,omitempty"`
	CreatedAt   int64     `json:"created_at"`
	UpdatedAt   int64     `json:"updated_at"`
}

// Image is a binary attachment uploaded against a task.
type Image struct {
	ID          string `json:"id"`
	TaskID      string `json:"task_id"`
	Filename    string `json:"filename"`
	MimeType    string `json:"mime_type"`
	SizeBytes   int64  `json:"size_bytes"`
	StoragePath string `json:"-"`
	UploadedAt  int64  `json:"uploaded_at"`
}
