'**
' * PerformanceMetricsTracker - A comprehensive performance tracking utility
' *
' * Provides timing capabilities using roTimespan for measuring application performance,
' * including app launch metrics, user interaction timings, and milestone tracking.
' * Automatically integrates with the tracking/logging system for analytics.
' *
' * @return {Object} Performance tracker instance with timing and logging methods
'**
Function PerformanceMetricsTracker() as Object
  return {
    '** @property {Object} trackingLoggingTask - Reference to the global tracking/logging task for sending metrics **
    trackingLoggingTask: invalid

    '** @property {Object} appLaunchMetrics - Storage for application launch timing metrics **
    appLaunchMetrics: {}

    '** @property {Object} metrics - Storage for general performance metrics with support for multi-entry events **
    metrics: {}

    '** @property {Object} milestones - Storage for point-in-time milestone timestamps **
    milestones: {}

    '** @property {Object} _activeTimers - Internal storage for active roTimespan timers **
    _activeTimers: {}

    '** @property {Object} samplePercent - Sampling rates for different metric types to control logging frequency **
    samplePercent: {
      default: 0.1
      app_launch_metrics: 0.1
    }

    '**
    ' * Starts timing for an app launch metric event
    ' *
    ' * Convenience method that delegates to startMetricTiming for app launch specific events.
    ' * Results will be stored in the appLaunchMetrics object when timing ends.
    ' *
    ' * @param {String} eventName - Unique identifier for the app launch event to time
    ' * @return {Void}
    ' * @example tracker.startAppLaunchMetricTiming("content_controller_init")
    '**
    startAppLaunchMetricTiming: Function(eventName as String) as Void
      m.startMetricTiming(eventName)
    End Function

    '**
    ' * Starts timing for a general performance metric event
    ' *
    ' * Creates a new roTimespan timer and stores it for the specified event.
    ' * If a timer already exists for this event, the method returns early to prevent
    ' * overwriting an active timer.
    ' *
    ' * @param {String} eventName - Unique identifier for the event to time
    ' * @return {Void}
    ' * @example tracker.startMetricTiming("homescreen_load")
    '**
    startMetricTiming: Function(eventName as String) as Void
      if m._activeTimers[eventName] <> invalid then
        return
      end if

      timer = CreateObject("roTimespan")
      m._activeTimers[eventName] = timer
    End Function

    '**
    ' * Ends timing for an app launch metric and stores result in appLaunchMetrics
    ' *
    ' * Stops the timer for the specified event and stores the elapsed time in milliseconds
    ' * in the appLaunchMetrics object. If no active timer exists, the operation is ignored.
    ' *
    ' * @param {String} eventName - Name of the event to stop timing
    ' * @return {Void}
    ' * @example tracker.endAppLaunchMetricTiming("content_controller_init")
    '**
    endAppLaunchMetricTiming: Function(eventName as String)
      elapsedMs = m.stopMetricTiming(eventName)

      if elapsedMs <> -1 then
        m.appLaunchMetrics[eventName] = elapsedMs
      end if
    End Function

    '**
    ' * Ends timing for a general metric and stores result with optional context
    ' *
    ' * Stops the timer and stores the result in the metrics object. Supports additional
    ' * context data and handles multi-entry events (like scroll performance) by storing
    ' * results in arrays. Single-entry events store just the timing value or context object.
    ' *
    ' * @param {String} eventName - Name of the event to stop timing
    ' * @param {Object} additionalContext - Optional context data to include with timing
    ' * @return {Void}
    ' * @example tracker.endMetricTiming("scroll_performance", {direction: "horizontal", distance: 500})
    '**
    endMetricTiming: Function(eventName as String, additionalContext = invalid as Object)
      MULTI_ENTRY_EVENTS = { "horizontal_scroll_performance": true, "vertical_scroll_performance": true }
      elapsedMs = m.stopMetricTiming(eventName)

      if elapsedMs <> -1 then
        newMetric = {}
        if additionalContext <> invalid then
          additionalContext.time = elapsedMs
          newMetric.append(additionalContext)
        else
          newMetric = elapsedMs
        end if

        if MULTI_ENTRY_EVENTS.DoesExist(eventName) then
          if m.metrics[eventName] = invalid then
            m.metrics[eventName] = [newMetric]
          else
            m.metrics[eventName].push(newMetric)
          end if
        else
          m.metrics[eventName] = newMetric
        end if

      end if
    End Function

    '**
    ' * Internal method to stop a timer and return elapsed time
    ' *
    ' * Stops the roTimespan timer for the specified event, calculates elapsed time
    ' * in milliseconds, and cleans up the timer reference. This is a utility method
    ' * used by other timing methods.
    ' *
    ' * @param {String} eventName - Name of the event timer to stop
    ' * @return {Integer} Elapsed time in milliseconds, or -1 if timer not found
    ' * @private
    '**
    stopMetricTiming: Function(eventName as String)
      if m._activeTimers[eventName] <> invalid then
        timer = m._activeTimers[eventName]
        elapsedMs = timer.totalMilliseconds()
        m._activeTimers.delete(eventName)

        return elapsedMs
      end if

      return -1
    End Function

    '**
    ' * Logs all app launch metrics to the tracking system
    ' *
    ' * Sends all collected app launch metrics to the analytics/logging system
    ' * using the configured sample rate. This should be called once when the
    ' * app launch sequence is complete.
    ' *
    ' * @return {Void}
    ' * @example tracker.logAppLaunchMetrics()
    '**
    logAppLaunchMetrics: Function() as Void
      m.fireMetricLogEvent(m.appLaunchMetrics, "app_launch_metrics")
    End Function

    '**
    ' * Logs a specific metric to the tracking system
    ' *
    ' * Sends a single named metric to the analytics/logging system. If the metric
    ' * doesn't exist, the method returns early without logging anything.
    ' *
    ' * @param {String} eventName - Name of the metric to log
    ' * @return {Void}
    ' * @example tracker.logMetric("homescreen_load_time")
    '**
    logMetric: Function(eventName as String) as Void
      if m.metrics[eventName] = invalid
        return
      end if

      m.fireMetricLogEvent(m.metrics[eventName], eventName)
    End Function

    '**
    ' * Internal method to send metrics to the tracking/logging system
    ' *
    ' * Formats and sends metric data to the global tracking system with appropriate
    ' * sampling rates and metadata. Handles both object and array metric formats.
    ' * Automatically retrieves the global tracking task if not already cached.
    ' *
    ' * @param {Object} metrics - The metric data to send (object or array)
    ' * @param {String} eventName - Name of the event for categorization and sampling
    ' * @return {Void}
    ' * @private
    '**
    fireMetricLogEvent: Function(metrics as Object, eventName as String) as Void
      if m.trackingLoggingTask = invalid
        m.trackingLoggingTask = getGlobalAA().global.trackingLoggingTask
      end if

      ' Convert the metrics to a string if it is an array.
      if type(metrics) = "roArray" then
        metrics = {
          metrics: FormatJson(metrics)
        }
      end if

      if m.trackingLoggingTask <> invalid
        samplePercent = m.samplePercent[eventName]
        if samplePercent = invalid then
          samplePercent = m.samplePercent.default
        end if

        message = {
          message: metrics
          serverTypeName: "performanceMetrics"
          subtype: eventName
          level: "info"
          samplePercent: samplePercent
        }
        m.trackingLoggingTask.logMsg = message
      end if
    End Function

    '**
    ' * Marks a milestone timestamp for point-in-time events
    ' *
    ' * Records the current timestamp using roTimespan for events that represent
    ' * specific moments rather than durations. Useful for tracking when key
    ' * application states are reached or important events occur.
    ' *
    ' * @param {String} milestoneName - Unique identifier for the milestone event
    ' * @return {Void}
    ' * @example tracker.markMilestone("first_screen_visible")
    '**
    markMilestone: Function(milestoneName as String) as Void
      timestamp = CreateObject("roTimespan")
      m.milestones[milestoneName] = timestamp.totalMilliseconds()
    End Function

    '**
    ' * Logs a specific milestone to the tracking system
    ' *
    ' * Sends a recorded milestone timestamp to the analytics/logging system.
    ' * If the milestone doesn't exist, the method returns early without logging.
    ' *
    ' * @param {String} milestoneName - Name of the milestone to log
    ' * @return {Void}
    ' * @example tracker.logMilestone("app_interactive")
    '**
    logMilestone: Function(milestoneName as String) as Void
      if m.milestones[milestoneName] <> invalid then
        m.fireMetricLogEvent(m.milestones[milestoneName], milestoneName)
      end if
    End Function

    '**
    ' * Resets all stored metrics, timers, and milestones
    ' *
    ' * Clears all collected data including app launch metrics, general metrics,
    ' * milestone timestamps, and active timers. Useful for testing or when
    ' * starting a fresh measurement session.
    ' *
    ' * @return {Void}
    ' * @example tracker.reset()
    '**
    reset: Function() as Void
      m.appLaunchMetrics.clear()
      m._activeTimers.clear()
      m.milestones.clear()
      m.metrics.clear()
    End Function
  }
End Function

