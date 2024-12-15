---@diagnostic disable: undefined-global
--[[

    PureUNC.lua

    Just one big file to expose any executors that spoof their UNC!
    Nobody likes those guys, so let's just normalize a way to detect these hooligans.

    <---------->

    Written by: Suno (https://github.com/mr-suno)
    Version: 1.0.0
    Date: December 15th, 2024

]]

print("");
print("----------------")
print("");

-- Script Setup Process

local Passes = 0;   -- Index of how many scripts pass the test
local Failures = 0; -- Failures of the test
local Unknown = 0;  -- Unknown segments of the test
local Total = 0;    -- There usually should be 83 UNC (84 in our case, including Require)
local Running = 0;  -- Currently running processes

-- Constants & Functions

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");

local LocalPlayer = Players.LocalPlayer;
local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts");

local function getGlobal(path)
    local value = getfenv(0);

    while value ~= nil and path ~= "" do
        local name, nextValue = string.match(path, "^([^.]+)%.?(.*)$");

        value = value[name];
        path = nextValue;
    end

    return value;
end

local function test(name, aliases, callback)
    Running = Running + 1;

    task.spawn(function()
        if not callback then
            print("⏺️", name);
        elseif not getGlobal(name) then
            Failures = Failures + 1;

            warn("❌", name, "not found");
        else
            local Success, _ = pcall(callback);

            if Success then
                Passes = Passes + 1;

                print("✅", name .. (Response and " • " .. Response or ""));
            else
                Failures = Failures + 1;

                warn("❌", name, "failed");
            end
        end

        local Undefined = {};

        for _, Alias in pairs(aliases) do
            if getGlobal(Alias) then
                table.insert(Undefined, Alias);
            end
        end

        if #Undefined > 0 then
            Unknown = Unknown + 1;

            warn("⚠️", table.concat(Undefined, ", "));
        end

        Running = Running - 1;
    end)
end

-- Actual Detection

print("PureUNC True Environment Check");
print("An open-sourced Anti-Spoofing UNC test by Suno");
print("");
print("✅ - Pass, ❌ - Fail, ⚠️ - Missing aliases, ⏺️ - No test");
print("")

-- Summary

task.defer(function()
    repeat task.wait() until Running == 0;

    local Rate = math.round(Passes / (Passes + Failures));
    local TotalUNC = Passes .. " out of " .. (Passes + Failures) .. " UNC passed";

    print("");
    print("PureUNC Summary • Written by Suno");
    print("");

    print("✅ Finished with an overall success rate of " .. Rate .. "% (" .. TotalUNC .. ")");
    print("❌ " .. Failures .. " tests failed");
    print("⚠️ " .. Unknown .. " globals are missing aliases!");
end)

test("require", {}, function()
    local CoreScript = PlayerScripts:FindFirstChild("PlayerModule");

    require(CoreScript);

    assert(require);
end)

test("restorefunction", {}, function()
    local Initial = error;

    local Clone = hookfunction(Initial, function()
        return false;
    end)

    restorefunction(Initial);

    assert(Initial() == false);
    assert(Clone()   == false);
    assert(Initial   == Clone);
end)

test("hookfunction", {"replaceclosure"}, function()
    local Initial = math.ceil;

    local Clone = hookfunction(Initial, function()
        return false;
    end)

    assert(Initial() == false, "Function should return false");
    assert(Clone()   == true,  "Original function should return as a math function");
    assert(Initial   ~= Clone, "Original function should not equal the clone");
end)

test("getcallingscript", {});

test("loadstring", {}, function()
    local URL = "https://pastebin.com/raw/4KdWjunz";
    local Connection = loadstring(game:HttpGet(URL))();

    assert(Connection == true, "Connection was not successfully returned");
end)
