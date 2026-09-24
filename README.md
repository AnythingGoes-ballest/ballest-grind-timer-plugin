# Grind Timer

A plugin for the [Ballest plugin manager](https://github.com/AnythingGoes-ballest/ballest-plugin-manager): a
Trackmania-style green timer for Ballest of Them All.

```
0:42:17        total time spent racing (green while a race runs, dark green otherwise)
restarts 36    restarts from the beginning of the track
```

- **Time** counts only while a race is running. It keeps counting through checkpoint respawns and stops in menus,
  after the finish and during a restart. With the **Count all time** setting on, it is a plain timer instead: it
  counts all the time the game is open, menus and loading included (the timer itself still only shows on a track).
- **Restarts** counts restarts from the beginning of the track: Backspace, or R before the first checkpoint.
  Checkpoint respawns and falls don't count. The count is the game's own (the ball's restart counter), not key
  presses, so rebinding keys changes nothing.
- The totals add up across tracks and survive relaunches.
- While the cursor is on screen (the pause menu, for example), **pause timer** and **reset** buttons appear under the
  timer, and the timer can be dragged anywhere on screen. Its position is remembered.
- **Settings** (footer **plugins** > **installed** > Grind Timer > **settings**): show or hide the timer
  (hidden, it keeps counting), count all time or racing time only, the size of the time and of the restarts line,
  how dark the box behind it is, whether the restarts line shows, and **reset position**.

## Install

In the game: footer **plugins** > **browse** > Grind Timer > **install**. Needs the plugin manager host
0.4.0 or newer.

## How it works

`main.as` uses the host's `Race` API (`IsActive`, `Restarts`) and saves its totals with `Storage`
(`%LOCALAPPDATA%\Ballest\Saved\PluginManager\storage\grind-timer.txt`).

## License

MIT
