using System.Drawing;
using GMSL;
using Underanalyzer;
using UndertaleModLib;
using UndertaleModLib.Util;
using UndertaleModLib.Models;

namespace devtools;

public class Mod : GMSLMod
{
    // Runs when patching the game when changes are detected.
    public override void Patch()
    {
        Console.WriteLine($"[devTools]: Adding code...");
        AddCode();
    }

    // Runs before every startup.
    public override void Start() {}

    public void AddCode()
    {
        var obj = NewObject("vsCoreMod_ws_server", null, false, false, true);
        // TODO add overloads of these that take obj directly in gmsl
        CreateObjectCodeFromFile("init_ws.gml", "vsCoreMod_ws_server", EventType.Create);
        CreateObjectCodeFromFile("handle_ws_event.gml", "vsCoreMod_ws_server", EventType.Other, EventSubtypeOther.AsyncNetworking);
        // TODO add Destroy handler
        AddObjectToRoom("scene_init", obj, "Instances");
    }
}
