// Grind Timer: a Trackmania-style green timer on every track.
//
//   0:42:17          total time spent racing (green while a race runs, dark green otherwise), or with "Count all
//                    time" on, all the time the game is open (in menus and loading too)
//   restarts 36      restarts from the beginning of the track (Backspace, or R before the first checkpoint);
//                    checkpoint respawns and falls don't count
//
// Both come from the game (Race::IsActive, Race::Restarts), not from key presses, so rebinding keys changes
// nothing. They add up across tracks and survive relaunches (Storage). While the cursor is on screen (the pause
// menu, for example) the timer can be dragged anywhere, and pause and reset buttons appear under it. Showing it,
// its sizes and the background are in the plugin manager's settings.

[Setting name="Show timer" description="Off hides the timer; it keeps counting (use pause timer to stop it)"]
bool ShowTimer = true;

[Setting name="Count all time" description="On: counts all the time the game is open. Off: only time spent racing"]
bool CountAllTime = false;

[Setting name="Time size" min=16 max=160 description="Height of the time, in pixels"]
float TimeSize = 56;

[Setting name="Restarts size" min=10 max=80 description="Height of the restarts line, in pixels"]
float RestartsSize = 22;

[Setting name="Background" min=0 max=1 description="How dark the box behind the timer is (0: none)"]
float BackgroundOpacity = 0.35f;

[Setting name="Show restarts"]
bool ShowRestarts = true;

const float COUNTING_R = 0.235f, COUNTING_G = 1.0f, COUNTING_B = 0.353f;     // the overlay's green
const float IDLE_R = 0.157f, IDLE_G = 0.549f, IDLE_B = 0.235f;               // dark green: not racing or paused
const double SAVE_EVERY = 5.0;                                                // seconds

UI::Window@ timerWindow;
UI::Text@ timeText;
UI::Text@ restartText;
UI::Button@ pauseButton;
UI::Button@ resetButton;

double seconds = 0;             // total racing time
int restarts = 0;               // total restarts from the beginning
bool paused = false;
int seenRestarts = 0;           // Race::Restarts() when last read
double lastTick = 0;
double lastSave = 0;
bool dirty = false;             // changed since the last save
int shownMode = -1;             // 1 counting, 0 idle; the colour is only set when it changes

void Main()
{
    seconds = parseFloat(Storage::Get("seconds", "0"));
    restarts = int(parseInt(Storage::Get("restarts", "0")));
    paused = Storage::Get("paused", "false") == "true";
    seenRestarts = Race::Restarts();
    lastTick = lastSave = Host::Time();

    //   0:42:17
    //   restarts 36
    //   [pause timer] [reset]      (only while the cursor is on screen)
    @timerWindow = UI::CreateWindow();
    timerWindow.SetAnchor(0, 0);
    timerWindow.SetPivot(0, 0);
    timerWindow.SetOffset(40, 40);
    timerWindow.visible = false;
    @timeText = timerWindow.AddText(TimeText(), TimeSize);
    timerWindow.NewRow();
    @restartText = timerWindow.AddText(RestartText(), RestartsSize);
    timerWindow.NewRow();
    @pauseButton = timerWindow.AddButton(paused ? "start timer" : "pause timer");
    @resetButton = timerWindow.AddButton("reset");
    timerWindow.movable = true;     // after SetOffset: that is where "reset position" puts it back
    OnSettingsChanged();

    Log::Info("grind timer at " + TimeText() + ", " + restarts + " restarts" + (paused ? " (paused)" : ""));
}

// The plugin manager changed a setting (sizes, background, restarts line).
void OnSettingsChanged()
{
    timeText.size = TimeSize;
    restartText.size = RestartsSize;
    restartText.visible = ShowRestarts;
    timerWindow.SetBackground(0, 0, 0, BackgroundOpacity);
}

// H:MM:SS
string TimeText()
{
    int total = int(seconds);
    return (total / 3600) + ":" + formatInt((total / 60) % 60, "0", 2) + ":" + formatInt(total % 60, "0", 2);
}

string RestartText()
{
    return "restarts " + restarts + (paused ? " (paused)" : "");
}

void Save()
{
    Storage::Set("seconds", formatFloat(seconds, "", 0, 3));
    Storage::Set("restarts", "" + restarts);
    Storage::Set("paused", paused ? "true" : "false");
    lastSave = Host::Time();
    dirty = false;
}

void Update(float dt)
{
    double now = Host::Time();
    double step = now - lastTick;
    if (step > 1.0 && !CountAllTime)
        step = 1.0;                 // racing time: a hitch or a long load never adds more than a second
    lastTick = now;

    bool onTrack = Race::OnTrack();
    timerWindow.visible = onTrack && ShowTimer;
    bool cursor = UI::CursorShown();
    pauseButton.visible = cursor;
    resetButton.visible = cursor;

    if (pauseButton.Clicked())
    {
        paused = !paused;
        pauseButton.label = paused ? "start timer" : "pause timer";
        Log::Info(paused ? "paused" : "started");
        Save();
    }
    if (resetButton.Clicked())
    {
        seconds = 0;
        restarts = 0;
        Log::Info("reset");
        Save();
    }

    int nowRestarts = Race::Restarts();
    if (!paused && nowRestarts > seenRestarts)
    {
        restarts += nowRestarts - seenRestarts;
        dirty = true;
    }
    seenRestarts = nowRestarts;

    bool counting = !paused && (CountAllTime || (onTrack && Race::IsActive()));
    if (counting)
    {
        seconds += step;
        dirty = true;
    }

    int mode = counting ? 1 : 0;
    if (mode != shownMode)
    {
        if (counting)
            timeText.SetColor(COUNTING_R, COUNTING_G, COUNTING_B, 1);
        else
            timeText.SetColor(IDLE_R, IDLE_G, IDLE_B, 1);
        shownMode = mode;
    }
    timeText.text = TimeText();
    restartText.text = RestartText();

    if (dirty && now - lastSave > SAVE_EVERY)
        Save();
}
