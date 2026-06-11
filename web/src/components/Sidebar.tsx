import { useState } from "react";
import type { Project } from "../lib/api";
import { useCreateProject, useProjects } from "../hooks/queries";

interface Props {
  selectedId: string | null;
  onSelect: (project: Project) => void;
}

export function Sidebar({ selectedId, onSelect }: Props) {
  const projects = useProjects();
  const createProject = useCreateProject();
  const [creating, setCreating] = useState(false);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");

  return (
    <aside className="w-64 shrink-0 border-r border-slate-200 bg-white p-4 flex flex-col gap-3">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-bold tracking-tight">taskline</h1>
        <button
          className="text-xs px-2 py-1 rounded bg-slate-900 text-white hover:bg-slate-700"
          onClick={() => setCreating((v) => !v)}
        >
          {creating ? "Cancel" : "+ New"}
        </button>
      </div>
      {creating && (
        <form
          onSubmit={async (e) => {
            e.preventDefault();
            if (!name.trim()) return;
            const created = await createProject.mutateAsync({ name, description });
            setName("");
            setDescription("");
            setCreating(false);
            onSelect(created);
          }}
          className="space-y-2 border-b border-slate-200 pb-3"
        >
          <input
            className="w-full text-sm border border-slate-300 rounded px-2 py-1"
            placeholder="project name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            autoFocus
          />
          <input
            className="w-full text-sm border border-slate-300 rounded px-2 py-1"
            placeholder="description (optional)"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
          <button
            type="submit"
            disabled={createProject.isPending}
            className="w-full text-sm bg-emerald-600 text-white rounded py-1 hover:bg-emerald-700 disabled:opacity-50"
          >
            {createProject.isPending ? "Creating…" : "Create"}
          </button>
          {createProject.error && (
            <p className="text-xs text-red-600">{(createProject.error as Error).message}</p>
          )}
        </form>
      )}
      <nav className="flex-1 overflow-auto">
        {projects.isLoading && <p className="text-sm text-slate-500">Loading…</p>}
        {projects.error && (
          <p className="text-sm text-red-600">
            Failed to load projects: {(projects.error as Error).message}
          </p>
        )}
        {projects.data?.length === 0 && (
          <p className="text-xs text-slate-500">No projects yet.</p>
        )}
        <ul className="space-y-1">
          {projects.data?.map((p) => {
            const active = p.id === selectedId;
            return (
              <li key={p.id}>
                <button
                  onClick={() => onSelect(p)}
                  className={
                    "w-full text-left text-sm px-2 py-1.5 rounded transition " +
                    (active
                      ? "bg-slate-900 text-white"
                      : "hover:bg-slate-100 text-slate-700")
                  }
                >
                  {p.name}
                </button>
              </li>
            );
          })}
        </ul>
      </nav>
    </aside>
  );
}
