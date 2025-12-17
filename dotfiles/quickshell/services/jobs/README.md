# Job Queue System

A background job queue system for Quickshell that allows asynchronous task execution with dependency chaining and progress tracking.

## Overview

This system provides a way to queue and execute long-running background tasks without blocking the UI. Jobs can be chained together so that one job waits for another to complete before starting.

## Architecture

### Core Components

- **BaseJob.qml**: Abstract base class that all job types extend. Provides common functionality for job lifecycle, progress tracking, and process management.

- **JobQueue.qml**: Manages job execution, enforcing concurrency limits and handling job dependencies.

- **JobManager.qml**: Public API for creating and enqueueing jobs. Registers available job types and provides convenience methods.

- **JobNotification.qml**: Sends desktop notifications for job status changes (started, completed, failed).

### Job Runners

Individual job implementations live in `runners/`. Each job extends BaseJob and implements the `execute()` function:

- **GenerateAIColorJob.qml**: Generates color palettes from images using AI
- **SaveAIColorFileJob.qml**: Saves generated color data to disk
- **ApplyAIColorJob.qml**: Applies a color theme and wallpaper
- **YoutubeConversionJob.qml**: Converts YouTube videos

## Creating a New Job

### 1. Create the Job Runner

Create a new file in `runners/` that extends BaseJob:

```qml
import QtQuick
import Quickshell.Io
import ".." as Jobs

Jobs.BaseJob {
    id: job

    // Parse job arguments
    property string myArg: args.length > 0 ? args[0] : ""

    // Job metadata
    jobName: "My Custom Job"
    notificationIcon: "emblem-system"

    function execute() {
        // Validate inputs
        if (!myArg) {
            _setFailed("Missing required argument");
            return;
        }

        _updateProgress(10, "Starting work...");

        // Create a process
        const process = _createProcess(
            ["my-command", myArg],
            (data) => {
                // stdout handler
                _updateProgress(50, "Processing output...");
                const result = { output: data };
                _setCompleted(result);
            },
            (data) => {
                // stderr handler
                console.error("Error:", data);
            },
            (exitCode, exitStatus) => {
                // exit handler
                if (exitCode !== 0 && status === "running") {
                    _setFailed("Command failed with exit code: " + exitCode);
                }
            }
        );

        if (!process) {
            _setFailed("Failed to create process");
            return;
        }

        process.running = true;
    }
}
```

### 2. Register the Job Type

Add your job to `JobManager.qml`:

```qml
property var jobComponents: ({
    "YoutubeConversion": "YoutubeConversionJob.qml",
    "MyCustomJob": "MyCustomJob.qml"  // Add this line
})
```

### 3. Enqueue the Job

From your UI code:

```qml
import qs.services.jobs as Jobs

// Simple job
const jobId = Jobs.JobManager.enqueueJob(
    "MyCustomJob",
    ["argument1", "argument2"],
    "my-context-id",
    (result) => {
        console.log("Job completed:", result);
    }
);
```

## Job Dependencies and Chaining

Jobs can depend on other jobs. A dependent job will wait until its dependency completes, and it will receive the dependency's result.

```qml
// Queue first job
const job1 = Jobs.JobManager.enqueueJob(
    "GenerateAIColor",
    [wallpaperPath, true],
    "color-gen",
    null
);

// Queue second job that depends on first
const job2 = Jobs.JobManager.enqueueJob(
    "SaveAIColorFile",
    [null, "/etc/nixos/nix/themes"],
    "color-save",
    (result) => {
        console.log("Saved to:", result.filePath);
    },
    job1  // This job waits for job1 to complete
);

// Queue third job that depends on second
const job3 = Jobs.JobManager.enqueueJob(
    "ApplyAIColor",
    ["", wallpaperPath],
    "color-apply",
    null,
    job2  // This job waits for job2 to complete
);
```

### Using Dependency Results

When a job depends on another, it can access the parent job's result via `dependencyResult`:

```qml
Jobs.BaseJob {
    // If dependency provides colorData, use it
    property var colorData: {
        if (dependencyResult && dependencyResult.colorData) {
            return dependencyResult.colorData;
        }
        return args.length > 0 ? args[0] : null;
    }

    function execute() {
        // Use colorData which may have come from dependency
        console.log("Using color data:", colorData);
    }
}
```

## BaseJob API

### Properties

- `jobId`: Unique identifier for this job
- `jobType`: Type string used to create this job
- `jobName`: Human-readable name for notifications
- `args`: Array of arguments passed to the job
- `status`: Current status ("pending", "running", "completed", "failed", "waiting_for_dependency")
- `progress`: Progress percentage (0-100)
- `result`: Result object set when job completes
- `errorMessage`: Error message set when job fails
- `dependsOnJobId`: ID of job this job depends on
- `dependencyResult`: Result from dependency job (if any)

### Methods

Protected methods for subclasses to call:

- `_updateProgress(percent, message)`: Update job progress
- `_setCompleted(resultData)`: Mark job as successfully completed
- `_setFailed(error)`: Mark job as failed with error message
- `_createProcess(command, onStdout, onStderr, onExited)`: Create a background process with handlers

### Signals

- `started()`: Emitted when job starts executing
- `progressUpdated(percent, message)`: Emitted when progress changes
- `completed(result)`: Emitted when job completes successfully
- `failed(error)`: Emitted when job fails

## Important Notes for Quickshell

This system is built for Quickshell, which uses QML but has some differences from standard Qt Quick:

1. **Process Creation**: Always use `_createProcess()` helper which properly configures `SplitParser` for stdout/stderr
2. **Signal Connections**: Connect signals immediately after creating objects, before setting `running = true`
3. **Property Bindings**: Use proper QML property binding syntax with `Qt.binding()` when dynamically updating properties
4. **Error Handling**: Always check for null/undefined and provide error messages via `_setFailed()`

## Configuration

### Concurrency

Max concurrent jobs is set in `JobQueue.qml`:

```qml
property int maxConcurrentJobs: 3
```

### Notifications

Notification settings in `JobNotification.qml`:

```qml
property string appName: "Quickshell Jobs"
property int defaultExpireTime: 5000  // milliseconds
```

## Debugging

Enable debug logging in jobs by adding console.log statements:

```qml
function execute() {
    console.log("Starting job:", jobId, "with args:", args);
    // ... rest of implementation
}
```

Check job queue status:

```qml
const stats = Jobs.JobManager.getStatistics();
console.log("Queue stats:", JSON.stringify(stats));

const allJobs = Jobs.JobManager.getAllJobs();
console.log("Running jobs:", allJobs.running.length);
```

## Common Patterns

### Long-Running Process

```qml
function execute() {
    const process = _createProcess(
        ["long-running-command"],
        (data) => _updateProgress(50, "Processing..."),
        (data) => console.error(data),
        (exitCode, exitStatus) => {
            if (exitCode === 0) {
                _setCompleted({ success: true });
            } else {
                _setFailed("Process failed");
            }
        }
    );
    process.running = true;
}
```

### Parsing JSON Output

```qml
function execute() {
    const process = _createProcess(
        ["command-that-outputs-json"],
        (data) => {
            try {
                const result = JSON.parse(data);
                _setCompleted(result);
            } catch (e) {
                _setFailed("Invalid JSON: " + e.toString());
            }
        },
        null,
        null
    );
    process.running = true;
}
```

### Multi-Step Job

```qml
function execute() {
    _updateProgress(0, "Step 1: Downloading...");
    performStep1().then(() => {
        _updateProgress(33, "Step 2: Processing...");
        return performStep2();
    }).then(() => {
        _updateProgress(66, "Step 3: Finalizing...");
        return performStep3();
    }).then(() => {
        _updateProgress(100, "Complete");
        _setCompleted({ success: true });
    }).catch(error => {
        _setFailed(error.toString());
    });
}
```
