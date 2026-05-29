import { DndContext } from "@dnd-kit/core";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { Task } from "../lib/api";
import { TaskCard } from "./TaskCard";

const task: Task = {
  id: "task-1",
  project_id: "project-1",
  title: "Clickable task card",
  description: "",
  type: "feature",
  state: "start",
  priority: 2,
  created_at: 1780051741142,
  updated_at: 1780051741142,
  depends_on: [],
  links: [],
  images: [],
};

function renderCard(onClick = vi.fn()) {
  render(
    <DndContext>
      <TaskCard task={task} isBlocked={false} onClick={onClick} />
    </DndContext>
  );

  return onClick;
}

describe("TaskCard", () => {
  afterEach(() => cleanup());

  it("opens the task editor when clicking the card content", async () => {
    const user = userEvent.setup();
    const onClick = renderCard();

    await user.click(screen.getByText("Clickable task card"));

    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it("does not open the editor when the pointer movement becomes a drag", () => {
    const onClick = renderCard();
    const card = screen.getByRole("button", { name: /clickable task card/i });

    fireEvent.pointerDown(card, { clientX: 0, clientY: 0 });
    fireEvent.pointerUp(card, { clientX: 8, clientY: 0 });

    expect(onClick).not.toHaveBeenCalled();
  });

  it("does not open the editor from a pointerup without a card pointerdown", () => {
    const onClick = renderCard();
    const card = screen.getByRole("button", { name: /clickable task card/i });

    fireEvent.pointerUp(card, { clientX: 0, clientY: 0 });

    expect(onClick).not.toHaveBeenCalled();
  });

  it("does not render the old edit-only affordance", () => {
    renderCard();

    expect(screen.queryByText(/^edit$/i)).toBeNull();
  });
});
