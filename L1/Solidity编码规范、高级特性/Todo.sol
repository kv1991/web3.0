
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Todo {
        string taskName;
        bool isCompleted;
    }

    uint256 taskCounter;
    Todo[] public todolist;

    function addTodo(string memory _name) public {
        taskCounter++;
        todolist.push(Todo({
            taskName: _name,
            isCompleted: false
        }));
    }

    function updateTaskName(uint256 taskId, string memory name) external {
        todolist[taskId].taskName = name;
    }

    function updateTaskCompleted(uint256 taskId) external {
        todolist[taskId].isCompleted = !todolist[taskId].isCompleted;
    }

    function getTodo(uint256 taskId) external view returns(string memory name, bool isCompleted) {
        Todo storage todo = todolist[taskId];
        return (todo.taskName, todo.isCompleted);
    }

}