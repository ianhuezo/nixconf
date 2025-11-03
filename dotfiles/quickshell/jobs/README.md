# Quickshell Job Manager System

A complete async job management system for running long-running tasks in the background without blocking the UI.

## Overview

The Job Manager system allows any action in Quickshell to be executed either in the foreground (blocking) or background (non-blocking). Users can choose to run tasks immediately or send them to the background, where they continue running even if the UI component is closed.

## Features

- **Opt-in background execution**: Users choose when to background a task
- **Visual feedback**: Buttons show job state with pulsing glows and progress indicators
- **System notifications**: Uses `notify-send` with rich content (images, HTML formatting)
- **Queue management**: Control concurrent job execution
- **Result retrieval**: Completed jobs store results for later use
- **Context tracking**: Jobs linked to UI elements via context IDs
- **Cancellable**: Stop running jobs from status widget
- **Extensible**: Easy to add new job types

## Architecture

### Core Components

#### 1. **BaseJob.qml**
Abstract base class for all jobs. Provides:
- Common properties: `jobId`, `args`, `status`, `progress`, `result`, `contextId`
- Signals: `started()`, `progressUpdated(percent, message)`, `completed(result)`, `failed(error)`
- State management and cleanup
- Abstract method: `execute()` - must be implemented by subclasses

#### 2. **JobManager.qml** (Singleton)
Central coordinator for all jobs. Provides:
- `enqueueJob(jobType, args, contextId, onComplete)` - Create and queue a job
- `enqueueJobForButton(buttonComponent)` - Create job from IconButton properties
- `getJob(jobId)` - Retrieve job by ID
- `getJobForContext(contextId)` - Get job by context ID
- `getJobResult(jobId)` - Get completed job result
- `cancelJob(jobId)` - Stop running job
- `retryJob(jobId)` - Re-run failed job
- `clearCompleted()` - Remove finished jobs from memory
- Statistics tracking

#### 3. **JobQueue.qml** (Singleton)
Manages job execution queue. Provides:
- Automatic queue processing
- Concurrent job limit (default: 3)
- Properties: `maxConcurrentJobs`, `queuedJobs[]`, `runningJobs[]`, `completedJobs[]`
- Functions: `enqueue(job)`, `dequeue()`, `pause()`, `resume()`, `clear()`

#### 4. **JobNotification.qml**
Wrapper for `notify-send` system notifications. Supports:
- Rich notifications with images (e.g., YouTube thumbnails)
- HTML formatting
- Custom icons and urgency levels
- Progress notifications (optional)
- Functions:
  - `sendJobStarted(jobName, jobId)`
  - `sendJobProgress(jobName, percent, message, icon)`
  - `sendJobCompleted(jobName, result, imagePath)`
  - `sendJobFailed(jobName, error, urgency)`

#### 5. **JobStatusWidget.qml**
Manual UI widget for monitoring all jobs. Shows:
- Running, queued, and completed jobs
- Per-job progress bars and status
- Elapsed time tracking
- Actions: cancel, retry, clear completed
- **Not auto-shown** - user opens explicitly via button/shortcut

### IconButton Integration

The existing `components/IconButton.qml` has been enhanced with optional job capabilities:

#### New Properties
- `canJobify: bool` - Whether this action can be backgrounded (default: false)
- `jobType: string` - Type of job to create (default: "")
- `jobArgs: var` - Function that returns args for job creation
- `jobContextId: string` - Unique ID to track job for this button instance
- `enableJobVisuals: bool` - Show job state visuals (default: true when jobType set)

#### New Signals
- `executeInBackground()` - Emitted when user requests background execution
- `jobComplete(result)` - Emitted when background job completes

#### Visual States

**Normal**: Standard IconButton appearance

**Jobifiable** (when `canJobify: true`):
```
┌─────────────────┐
│  ╭───────────╮  │  ← Subtle pulsing glow
│  │   ICON    │  │     Color: base0D (blue)
│  │           │  │     Opacity: 0.3-0.7
│  ╰───────────╯  │
└─────────────────┘
```

**Job Running**:
```
┌─────────────────┐
│  ╭───────────╮  │
│  │   ICON    │  │  ← Icon dimmed to 70%
│  │   (45%)   │  │  ← Progress percentage
│  ╰───────────╯  │
│   ◐ progress    │  ← Circular progress ring
└─────────────────┘
```

**Job Complete**:
```
┌─────────────────┐
│  ╭───────────╮  │
│  │   ICON  ✓ │  │  ← Green checkmark badge
│  │           │  │     Subtle green glow
│  ╰───────────╯  │
└─────────────────┘
```

#### User Interactions
- **Left click**: Normal behavior (foreground execution)
- **Right click**: Background execution (emits `executeInBackground`)
- **Shift+Click** or **Ctrl+Click**: Alternative for background execution
- **Long press**: Background execution (touch support)
- **Click when job complete**: Retrieves result, clears badge

## Built-in Job Types

### 1. YoutubeConversion
Downloads and converts YouTube videos to MP3.

**Args**: `[downloadUrl, bitrate, destinationPath]`

**Result**:
```javascript
{
    audioPath: string,
    thumbnailPath: string,
    title: string,
    uploader: string,
    success: bool
}
```

**Notification**: Shows thumbnail image when complete

### 2. SaveAIColorFile
Saves AI-generated color data to file system.

**Args**: `[colorData, filePath]`

**Result**:
```javascript
{
    filePath: string,
    success: bool
}
```

### 3. ApplyAIColor
Applies AI-generated colors to system/app configuration.

**Args**: `[colorData, targetConfig]`

**Result**:
```javascript
{
    applied: bool,
    colorCount: int
}
```

## Usage Examples

### Example 1: Simple Button (No Jobs)
Existing IconButton usage works unchanged:

```qml
import qs.components

IconButton {
    iconName: "edit-delete"
    tooltip: "Delete"
    onClicked: deleteItem()
}
```

### Example 2: Jobifiable Button (AI Color Save)

```qml
import qs.components

IconButton {
    iconName: "document-save"
    tooltip: "Save to File"

    // Enable job capabilities
    canJobify: generatedColors !== null
    jobType: "SaveAIColorFile"
    jobContextId: "ai-color-save"
    jobArgs: () => [generatedColors, FileConfig.aiColorsPath]

    onClicked: {
        // Left click: foreground execution
        saveColorFileDirect(generatedColors)
    }

    onExecuteInBackground: {
        // Right click: background execution
        JobManager.enqueueJobForButton(this)
    }

    onJobComplete: result => {
        // Called when background job finishes and user clicks button
        console.log("Background save complete:", result.filePath)
        showToast("Colors saved to " + result.filePath)
    }
}
```

**User Experience:**
1. Button shows pulsing glow when `generatedColors` is populated
2. Right-click button → job starts in background
3. Glow stops, circular progress appears
4. User can close window, job continues
5. When complete: system notification + green checkmark on button
6. Click button → retrieves result, badge disappears

### Example 3: YouTube Download

```qml
import qs.components

IconButton {
    iconName: "emblem-downloads"
    tooltip: "Download Video"

    canJobify: currentUrl.length > 0 && currentUrl.includes("youtube.com")
    jobType: "YoutubeConversion"
    jobContextId: "yt-download-" + currentUrl
    jobArgs: () => [currentUrl, "192", FileConfig.musicFolder]

    onClicked: {
        // Foreground: show progress UI, stay on page
        triggerDownloadProcess()
    }

    onExecuteInBackground: {
        // Background: can leave page/close window
        JobManager.enqueueJobForButton(this)
    }

    onJobComplete: result => {
        // Apply result to UI when retrieved
        youtubeThumbnail.source = result.thumbnailPath
        tagMP3FileProcess.mp3Path = result.audioPath
        tagMP3FileProcess.albumName = result.title
        tagMP3FileProcess.albumArtist = result.uploader
    }
}
```

### Example 4: Multiple Jobifiable Buttons

```qml
import qs.components

Rectangle {
    property var generatedColors: null

    Row {
        spacing: 10

        IconButton {
            iconName: "document-save"
            tooltip: "Save to File"
            canJobify: generatedColors !== null
            jobType: "SaveAIColorFile"
            jobContextId: "ai-color-save"
            jobArgs: () => [generatedColors, FileConfig.aiColorsPath]

            onClicked: { saveColorFileDirect(generatedColors) }
            onExecuteInBackground: { JobManager.enqueueJobForButton(this) }
            onJobComplete: result => { console.log("Saved:", result.filePath) }
        }

        IconButton {
            iconName: "checkbox-checked"
            tooltip: "Apply Colors"
            canJobify: generatedColors !== null
            jobType: "ApplyAIColor"
            jobContextId: "ai-color-apply"
            jobArgs: () => [generatedColors, "system"]

            onClicked: { applyColorsDirect(generatedColors) }
            onExecuteInBackground: { JobManager.enqueueJobForButton(this) }
            onJobComplete: result => { console.log("Applied", result.colorCount, "colors") }
        }
    }
}
```

### Example 5: Monitoring Jobs

```qml
import qs.components
import qs.jobs

Window {
    id: mainWindow

    // Button to open job monitor
    IconButton {
        iconName: "view-list-icons"
        tooltip: "View Background Jobs"
        onClicked: jobStatusWindow.show()
    }

    Window {
        id: jobStatusWindow
        visible: false
        width: 600
        height: 400
        title: "Background Jobs"

        JobStatusWidget {
            anchors.fill: parent
        }
    }
}
```

## Creating Custom Jobs

To create a new job type:

### 1. Create Job Component

```qml
// jobs/MyCustomJob.qml
import QtQuick
import Quickshell.Io
import "."

BaseJob {
    id: job

    // Define expected args structure
    property string inputPath: args.length > 0 ? args[0] : ""
    property string outputPath: args.length > 1 ? args[1] : ""

    function execute() {
        status = "running"
        started()

        // Create process or perform work
        const process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["my-command", "${inputPath}", "${outputPath}"]
            }
        `, job)

        process.finished.connect((exitCode) => {
            if (exitCode === 0) {
                result = { outputPath: outputPath, success: true }
                completed(result)
            } else {
                failed("Process failed with code " + exitCode)
            }
        })

        // Optional: Report progress
        // progressUpdated(50, "Processing...")

        process.running = true
    }
}
```

### 2. Register in Job.qml

```qml
// jobs/Job.qml
enum JobType {
    YoutubeToMp3 = 0,
    SaveAIColorFile = 1,
    MyCustomJob = 2  // Add here
}
```

### 3. Register in JobManager.qml

```qml
// jobs/JobManager.qml
property var jobComponents: ({
    "YoutubeConversion": "jobs/YoutubeConversionJob.qml",
    "SaveAIColorFile": "jobs/SaveAIColorFileJob.qml",
    "ApplyAIColor": "jobs/ApplyAIColorJob.qml",
    "MyCustomJob": "jobs/MyCustomJob.qml"  // Add here
})
```

### 4. Use in UI

```qml
IconButton {
    iconName: "my-icon"
    tooltip: "My Action"
    canJobify: true
    jobType: "MyCustomJob"
    jobContextId: "my-custom-job-" + someId
    jobArgs: () => [inputPath, outputPath]

    onClicked: { doActionNow() }
    onExecuteInBackground: { JobManager.enqueueJobForButton(this) }
    onJobComplete: result => { console.log("Done:", result.outputPath) }
}
```

## System Notification Examples

Jobs automatically send system notifications using `notify-send`:

**Job Started:**
```bash
notify-send \
    --app-name="Quickshell Jobs" \
    --icon="emblem-downloads" \
    --urgency=low \
    "YouTube Download Started" \
    "Downloading: Video Title..."
```

**Job Complete with Thumbnail:**
```bash
notify-send \
    --app-name="Quickshell Jobs" \
    --icon="emblem-default" \
    --image="/tmp/thumbnail.jpg" \
    --urgency=normal \
    --expire-time=5000 \
    "Download Complete" \
    "<b>Video Title</b>\nSaved to Music folder"
```

**Job Failed:**
```bash
notify-send \
    --app-name="Quickshell Jobs" \
    --icon="dialog-error" \
    --urgency=critical \
    "Job Failed" \
    "YouTube download failed: Network error"
```

## Configuration

### Adjust Concurrent Jobs

```qml
// In your shell.qml or config
Component.onCompleted: {
    JobQueue.maxConcurrentJobs = 5  // Default is 3
}
```

### Disable Job Visuals for Specific Button

```qml
IconButton {
    canJobify: true
    jobType: "MyJob"
    enableJobVisuals: false  // Disable glow/progress/badge
    // ... rest of config
}
```

## File Structure

```
jobs/
├── README.md                    (this file)
├── Job.qml                      (job metadata and types)
├── JobManager.qml               (central coordinator)
├── BaseJob.qml                  (abstract base class)
├── JobQueue.qml                 (queue management)
├── JobNotification.qml          (notify-send wrapper)
├── YoutubeConversionJob.qml     (YouTube download job)
├── SaveAIColorFileJob.qml       (AI color save job)
├── ApplyAIColorJob.qml          (AI color apply job)
└── JobStatusWidget.qml          (monitoring UI widget)

components/
└── IconButton.qml               (enhanced with job support)
```

## Best Practices

1. **Context IDs**: Use unique, descriptive context IDs that include relevant identifiers
   ```qml
   jobContextId: "ai-color-save-" + colorData.timestamp
   jobContextId: "yt-download-" + videoUrl
   ```

2. **Job Args**: Use functions that capture current state
   ```qml
   jobArgs: () => [this.currentData, this.targetPath]
   ```

3. **Foreground Fallback**: Always provide foreground execution option
   ```qml
   onClicked: { doActionImmediately() }  // Foreground
   onExecuteInBackground: { JobManager.enqueueJobForButton(this) }  // Background
   ```

4. **Result Handling**: Handle job completion gracefully
   ```qml
   onJobComplete: result => {
       if (result.success) {
           // Apply result
       } else {
           console.error("Job failed:", result.error)
       }
   }
   ```

5. **Progress Updates**: For long jobs, report progress regularly
   ```qml
   progressUpdated(percent, "Processing file 5/10...")
   ```

6. **Notifications**: Include relevant images/icons in notifications
   ```qml
   JobNotification.sendJobCompleted(
       "Download Complete",
       result,
       result.thumbnailPath  // Show thumbnail
   )
   ```

## Troubleshooting

### Button doesn't show glow
- Check `canJobify` is `true`
- Verify `jobType` is set and registered
- Ensure `enableJobVisuals` is `true` (default when jobType set)

### Job doesn't start
- Verify job type is registered in `JobManager.jobComponents`
- Check `jobArgs` function returns valid array
- Look for errors in console output

### Notifications don't appear
- Ensure `notify-send` is installed: `which notify-send`
- Check notification daemon is running (e.g., dunst, mako)
- Test manually: `notify-send "Test" "Message"`

### Job result not retrieved
- Ensure `jobContextId` is set correctly
- Check job completed successfully (not failed)
- Click button after job completes to retrieve result

## License

Part of the Quickshell project.
