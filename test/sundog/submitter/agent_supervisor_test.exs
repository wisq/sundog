defmodule Sundog.Submitter.AgentSupervisorTest do
  use ExUnit.Case
  import Mock

  alias Sundog.Submitter.AgentSupervisor, as: AgSup

  setup do
    start_supervised(Sundog.Submitter.Supervisor)
    :ok
  end

  test "find_or_create_process/2 creates process for metric and tags" do
    pid = AgSup.find_or_create_process("my.metric", [my: "tags"])
    assert is_pid(pid)
  end

  test "find_or_create_process/2 returns the same process on subsequent calls" do
    pid1 = AgSup.find_or_create_process("my.metric", [my: "tags"])
    assert is_pid(pid1)

    pid2 = AgSup.find_or_create_process("my.metric", [my: "tags"])
    assert pid1 == pid2
  end

  test "find_or_create_process/2 creates additional processes for other metrics and tags" do
    taglist = [
      {"my.metric", [my: "tags"]},
      {"other.metric", [other: "tags"]},
      {"no.tags", []},
      {"another.no.tags", []},
      {"same.tags", [same: "tags"]},
      {"other.same.tags", [same: "tags"]},
      {"multiple.tags", [a: "lot", of: "tags"]},
      {"multiple.tags", [a: "lot", of: "tags", plus: "a third tag"]},
    ]

    pids = (taglist ++ taglist ++ taglist)
           |> Enum.map(fn {metric, tags} -> AgSup.find_or_create_process(metric, tags) end)
    unique = pids |> Enum.uniq

    assert Enum.count(pids) == Enum.count(taglist) * 3
    assert Enum.count(unique) == Enum.count(taglist)
  end

  test "find_or_create_process/2 is not subject to race conditions" do
    pids = (1..100)
           |> Enum.map(fn _n ->
             Task.async(fn ->
               AgSup.find_or_create_process("some.metric", [some: "tags"])
             end)
           end)
           |> Enum.map(&Task.await/1)

    assert pids |> Enum.count == 100
    assert pids |> Enum.uniq |> Enum.count == 1
  end
end
