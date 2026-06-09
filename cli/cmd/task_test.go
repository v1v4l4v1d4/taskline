package cmd

import (
	"strings"
	"testing"
)

func TestTaskUpdateStateHelpMentionsTest(t *testing.T) {
	flag := taskUpdateCmd.Flag("state")
	if flag == nil {
		t.Fatal("state flag not found on taskUpdateCmd")
	}
	usage := flag.Usage
	if !strings.Contains(usage, "test") {
		t.Fatalf("state help %q does not mention test", usage)
	}
}
