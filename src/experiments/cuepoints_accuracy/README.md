# Ad Break Accuracy Experiment

Code initially from [RAF4RSG](https://github.com/rokudev/RAF4RSG-sample/blob/master/components/EntryScene.brs) and modified for specific test cases.


## Goal

Improve the user experience when entering a midroll ad break.  Tubi Roku channel currently plays ~0.25s of the next scene before stopping the video player for an ad break.  This is not a visually appealing experience.


## Variables

- [Video](https://sdkdocs.roku.com/display/sdkdoc/Video) node notificationInterval field: 0.5, 1.0
- Cuepoint placement - integer aligned vs. decimal: 00:05 vs. 00:05.5
- Video node controlled from SG render thread vs Task/Main thread
- Visibility of [Video](https://sdkdocs.roku.com/display/sdkdoc/Video) node: set visibility first vs. stop video first


## Methodology

Test stream was generated using ffmpeg and has accurate sub-second timestamps.

```
ffmpeg -f lavfi -i testsrc=duration=30:size=1280x720:rate=30:decimals=2 -pix_fmt yuv420p output.mp4
```

Tests were run by executing the channel test cases one at a time and doing video capture on the HDMI output of the Roku device.  The output was then analyzed to see what the last displayed time was before the video went black for the ad break.


## Data

| Test Case | interval | cuepoint | Run 1 | Run 2 | Run 3 | avg | error |
|-----------|-------|-------|-------|---|---|---|---|
|A|0.5|5|536|533|526|531.67|0.32 |
|B|1.0|5|523|533|526|527.33|0.27 |
|C|0.5|5.5|573|583|580|578.67|0.29 |
|D|1.0|5.5|620|630|626|625.33|0.75 |
|E|0.5|5|523|533|530|528.67|0.29 |
|F|1.0|5|523|533|526|527.33|0.27 |
|G|0.5|5.5|573|583|580|578.67|0.29 |
|H|1.0|5.5|623|630|630|627.67|0.78 |
|I|0.5|5|510|506|510|508.67|0.09 |
|J|1.0|5|506|506|510|507.33|0.07 |
|K|0.5|5.5|560|560|560|560.00|0.10 |
|L|1.0|5.5|610|610|610|610.00|0.60 |
|M|0.5|5|510|506|510|508.67|0.09 |
|N|1.0|5|510|510|510|510.00|0.10 |
|O|0.5|5.5|560|560| |560.00|0.10|
|P|1.0|5.5|606|603|610|606.33|0.56 |


## Takeaways

- Alignment of the notification events is always ~+0.2s from exact timestamps (e.g. 5.2,5.7,6.2,6.7,... instead of 5.0,5.5,6.0,...)
- Error isn't guaranteed better for notification intervals of 1.0s (events may by chance have exact alignment) but worse case is reduced to +0.5s
- Event handling time is almost negligible.  Real position values were like: 0.281, 0.781, 1.281... which almost exactly align with the error data above.  Conclusion is that with the experiment code, time between the event and the video actually stopping is negligible.  But...
- Stopping the video in the render thread seems to cause video playback to end sooner.  Errors were around 0.1s rather than 0.2s

