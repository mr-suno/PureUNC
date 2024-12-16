---@diagnostic disable: undefined-global
--[[

    PureUNC.lua

    Just one big file to expose any executors that spoof their UNC!
    Nobody likes those guys, so let's just normalize a way to detect these hooligans.

    <---------->

    Written by: Suno (https://github.com/mr-suno)
    Version: 1.0.1
    Date: December 15th, 2024

]]

print(string.rep("\n", 5));
print("----------------")
print("");

-- Script Setup Process

local InitialTime = tick();

local Passes = 0;   -- Index of how many scripts pass the test
local Failures = 0; -- Failures of the test
local Unknown = 0;  -- Unknown segments of the test

local TestQueue = {};
local SectionQueue = {};

-- Constants & Functions

local Players = game:GetService("Players");
local TextChatService = game:GetService("TextChatService");
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

local function sayMessage(Message)
    local ChatVersion = Enum.ChatVersion;

    if TextChatService.ChatVersion == ChatVersion.TextChatService then
        local Channels = TextChatService:FindFirstChild("TextChannels");
        local General = Channels:FindFirstChild("RBXGeneral");

        General:SendAsync(Message)
    else
        local DefaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents");
        local SayMessage = DefaultChat:FindFirstChild("SayMessageRequest");

        SayMessage:FireServer(Message, "All");
    end
end

local function section(Name)
    table.insert(SectionQueue, function()
        return Name;
    end);
end

local function test(Section, Name, Aliases, Callback)
    table.insert(TestQueue, {
        Section = Section,
        Name = Name,
        Aliases = Aliases or {},
        Callback = Callback
    });
end

local function beginTest()
    print(`PureUNC {identifyexecutor()} Environment Check`);
    print("An open-sourced Anti-Spoofing UNC test by Suno");
    print("");
    print("🟢 - Pass, 🔴 - Fail, 🟡 - Missing aliases, 🔵 - No test");

    local AllItems = {};
    local CurrentSection = nil;

    for _, Section in ipairs(SectionQueue) do
        table.insert(AllItems, Section);
    end

    for _, Case in ipairs(TestQueue) do
        table.insert(AllItems, Case);
    end

    for _, Item in ipairs(AllItems) do
        if type(Item) == "function" then
            Item();

            CurrentSection = nil;
        else
            local Section = Item.Section
            local Name = Item.Name
            local Aliases = Item.Aliases
            local Callback = Item.Callback

            if CurrentSection ~= Section then
                CurrentSection = Section;

                print("");
                print(`<----- {Section} Library ----->`);
                print("");

                CurrentSection = Section;
            end

            if not Callback then
                print("🔵", Name);
            elseif not getGlobal(Name) then
                Failures = Failures + 1;

                warn("🔴", Name, "not found");
            else
                local Success, Response = pcall(Callback);

                if Success then
                    Passes = Passes + 1;

                    print("🟢", Name .. (Response and " • " .. tostring(Response) or ""));
                else
                    Failures = Failures + 1;

                    warn("🔴", Name);

                    -- sayMessage(`{Name} is not supported with {identifyexecutor()}`);
                end
            end

            local Undefined = {};

            for _, Alias in pairs(Aliases) do
                if getGlobal(Alias) then
                    table.insert(Undefined, Alias);
                end
            end

            if #Undefined > 0 then
                Unknown = Unknown + 1;

                -- for _, Alias in pairs(Undefined) do
                --     warn("🟡", Name, "is missing alias:", Alias);
                -- end
            end
        end
    end

    -- Summary

    local Rate = math.round(Passes / (Passes + Failures) * 100);
    local TotalUNC = Passes .. " out of " .. (Passes + Failures) .. " UNC passed";

    print("");
    print("PureUNC Summary • Written by Suno");
    print(`Executor: {identifyexecutor()}`);
    print(`Time: {string.format("%.1f", tick() - InitialTime)} seconds ({string.format("%.3f", (tick() - InitialTime))} milliseconds)`);
    print("");

    print(`🟢 Finished with an overall success rate of {Rate}% ({TotalUNC})`);
    print(`🔴 {Failures} tests failed`);
    print(`🟡 {Unknown} globals are missing aliases!`);

    -- sayMessage(`PureUNC {identifyexecutor()} debug results: {Rate}% success rate, {Passes} out of {Passes + Failures} UNC passed`);
end

local function equal(X, Y)
    if X == Y then
        return true;
    end

    local Types = {
        ["function"] = true,
        ["table"] = true,
        ["userdata"] = true,
        ["thread"] = true,
    }

    local function Check(Pair, ToIndex)
        for Index, Value in pairs(Pair) do
            if Types[type(Value)] then
                if type(Y[Index]) ~= type(Value) then
                    return false;
                end
            elseif ToIndex[Index] ~= Value then
                return false;
            end
        end
    end

    Check(X, Y);
    Check(Y, X);

    return true;
end

-- Actual Detection

-- Non-UNC

section("<----- Non-UNC ----->");

test("Non-UNC", "require", {}, function()
    local CoreScript = PlayerScripts:FindFirstChild("PlayerModule");

    require(CoreScript);

    assert(require, "Require should be returning correct data");
end)

-- Cache

section("<----- Cache Library ----->");

test("Cache", "cache.invalidate", {});

test("Cache", "cache.iscached", {});

test("Cache", "cache.replace", {});

test("Cache", "cloneref", {});

test("Cache", "compareinstances", {});

-- Closures

section("<----- Closures ----->");

test("Closures", "checkcaller", {});

test("Closures", "clonefunction", {});

test("Closures", "getcallingscript", {});

test("Closures", "getscriptclosure", {"getscriptfunction"});

test("Closures", "hookfunction", {"replaceclosure"}, function()
    local Initial = math.ceil;

    local Clone = hookfunction(Initial, function()
        return false;
    end)

    assert(Initial() == false, "Function should return false");
    assert(Clone()   == true,  "Original function should return as a math function");
    assert(Initial   ~= Clone, "Original function should not equal the clone");
end)

test("Closures", "iscclosure", {});

test("Closures", "islclosure", {});

test("Closures", "isexecutorclosure", {"checkclosure", "isourclosure"});

test("Closures", "loadstring", {}, function()
    local URL = "https://pastebin.com/raw/4KdWjunz";
    local Connection = loadstring(game:HttpGet(URL))();

    assert(Connection == true, "Connection was not successfully returned");
end)

test("Closures", "newcclosure", {});

-- Console

section("<----- Console Library ----->");

test("Console", "rconsoleclear", {"consoleclear"});

test("Console", "rconsolecreate", {"consolecreate"});

test("Console", "rconsoledestroy", {"consoledestroy"});

test("Console", "rconsoleinput", {"consoleinput"});

test("Console", "rconsoleprint", {"consoleprint"});

test("Console", "rconsolesettitle", {"rconsolename", "consolesettitle"});

-- Cryptography

section("<----- Crypto Library ----->");

local CryptSample = "Hello, World"

test("Crypto", "crypt.base64encode", {"crypt.base64_encode", "crypt.base64.encode", "base64.encode", "base64_encode"}, function()
    local Initial = CryptSample;
    local Encoded = crypt.base64encode(Initial);

    assert(Encoded == "SGVsbG8sIFdvcmxk", "Encoded string should match the expected value");
end);

test("Crypto", "crypt.base64decode", {"crypt.base64_decode", "crypt.base64.decode", "base64.decode", "base64_decode"}, function()
    local Initial = "SGVsbG8sIFdvcmxk";
    local Decoded = crypt.base64decode(Initial);

    assert(Decoded == CryptSample, "Decoded string should match the expected value");
end);

test("Crypto", "crypt.encrypt", {}, function()
    local Initial = CryptSample;
    local Key = crypt.generatekey();
    local Encrypted, IV = crypt.encrypt(Initial, Key, nil, "CBC"); -- CBC is the encryption method used.

    assert(IV, "crypt.encrypt should return an IV");
    
    local Decrypted = crypt.decrypt(Encrypted, Key, IV, "CBC");

    assert(Decrypted == Initial, "Decrypted string should match the default value");
end);

test("Crypto", "crypt.decrypt", {}, function()
    local Initial = CryptSample;
    local Key, IV = crypt.generatekey(), crypt.generatekey();
    local Encrypted = crypt.encrypt(Initial, Key, IV, "CBC");
    local Decrypted = crypt.decrypt(Encrypted, Key, IV, "CBC");

    assert(Decrypted == Initial, "Decrypted string should match the default value");
end);

test("Crypto", "crypt.generatebytes", {}, function()
    local Size = math.random(10, 10);
    local Bytes = crypt.generatebytes(Size);

    assert(#crypt.base64decode(Bytes) == Size, `Decoded result should equate to {Size} bytes, got {#crypt.base64decode(Bytes)} decoded, {#Bytes} raw bytes`);
end);

test("Crypto", "crypt.generatekey", {}, function()
    local Key = crypt.generatekey();

    assert(#crypt.base64decode(Key) == 32, "Key should be 32 bytes long post-decoding");
end);

test("Crypto", "crypt.hash", {}, function()
    local Initial = CryptSample;
    local Algorithms = {
        "sha1",
        "sha384",
        "sha512",
        "md5",
        "sha256",
        "sha3-224",
        "sha3-256",
        "sha3-512"
    };

    for _, Algorithm in pairs(Algorithms) do
        local Hash = crypt.hash(Initial, Algorithm);

        assert(Hash, `crypt.hash on algorithm "{Algorithm}" should return a proper hash`)
    end
end);

-- Debug library

section("<----- Debug Library ----->");

test("Debug", "debug.getconstant", {});

test("Debug", "debug.getconstants", {});

test("Debug", "debug.getinfo", {});

test("Debug", "debug.getproto", {});

test("Debug", "debug.getprotos", {});

test("Debug", "debug.getstack", {});

test("Debug", "debug.getupvalue", {});

test("Debug", "debug.getupvalues", {});

test("Debug", "debug.setconstant", {});

test("Debug", "debug.setstack", {});

test("Debug", "debug.setupvalue", {});

-- Files

section("<----- File System ----->");

if isfolder and makefolder and delfolder then
    if isfolder(".PureUNC") then
        delfolder(".PureUNC");
    end

    makefolder(".PureUNC");
end

local FileTextSample = "Hello, World";

test("File System", "readfile", {}, function()
    writefile(".PureUNC/readfile.txt", FileTextSample);

    assert(readfile(".PureUNC/readfile.txt") == FileTextSample, "File text should match the default value");
end);

test("File System", "listfiles", {}, function()
    makefolder(".PureUNC/listfiles");

    writefile(".PureUNC/listfiles/exam_1.txt", FileTextSample);
    writefile(".PureUNC/listfiles/exam_2.txt", FileTextSample);

    local files = listfiles(".PureUNC/listfiles");

    assert(#files == 2, "Failed to return the proper index of files");
    assert(isfile(files[1]), "Failed to return a proper file path");
    assert(readfile(files[1]) == FileTextSample, "Did not return proper file text");

    -- Testing folders

    makefolder(".PureUNC/listfiles/subfolder");

    makefolder(".PureUNC/listfiles/subfolder/subfolder_1");
    makefolder(".PureUNC/listfiles/subfolder/subfolder_2");

    local folders = listfiles(".PureUNC/listfiles/subfolder");

    assert(#folders == 2, "Failed to return the proper index of folders");
    assert(isfolder(folders[1]), "Failed to return a proper folder path");
end);

test("File System", "writefile", {}, function()
    writefile(".PureUNC/writefile.txt", FileTextSample);

    assert(readfile(".PureUNC/writefile.txt") == FileTextSample, "Failed to write the file");

    local Issue = pcall(function()
        writefile(".PureUNC/writefile", FileTextSample);

        assert(isfile(".PureUNC/writefile.txt"));
    end)

    if not Issue then
        return "Executor requires an extension to write files";
    end
end);

test("File System", "makefolder", {}, function()
    makefolder(".PureUNC/makefolder");

    assert(isfolder(".PureUNC/makefolder"), "Failed to create the folder");
end);

test("File System", "isfile", {}, function()
    writefile(".PureUNC/isfile.txt", FileTextSample);

    assert(isfile(".PureUNC/isfile.txt") == true, "File should exist");
    assert(isfile(".PureUNC") == false, "Failed to return false to a Folder");
    assert(isfile(".PureUNC/nil") == false, "Failed to return false to a non-existent file");
end);

test("File System", "isfolder", {}, function()
    assert(isfolder(".PureUNC") == true, "Failed to return true to existing folder");
    assert(isfolder(".PureUNC/isfolder.txt") == false, "Returned true to a file");
end);

test("File System", "delfolder", {}, function()
    makefolder(".PureUNC/delfolder");

    assert(isfolder(".PureUNC/delfolder"), "Failed to correctly write the folder");

    delfolder(".PureUNC/delfolder");

    assert(isfolder(".PureUNC/delfolder") == false, "Failed to properly delete the folder");
end);

test("File System", "delfile", {}, function()
    writefile(".PureUNC/delfile.txt", FileTextSample);

    assert(isfile(".PureUNC/delfile.txt"), "Failed to write the file");

    delfile(".PureUNC/delfile.txt");

    assert(isfile(".PureUNC/delfile.txt") == false, "File could not be deleted");
end);

test("File System", "loadfile", {}, function()
    writefile(".PureUNC/loadfile.txt", "return ... + 1");

    assert(assert(loadfile(".PureUNC/loadfile.txt"))(1) == 2, "Failed to load file with proper arguments");

    writefile(".PureUNC/loadfile.txt", FileTextSample);

    local Callback, Error = loadfile(".PureUNC/loadfile.txt");

    assert(Error and not Callback, "Failed to return error message")
end);

test("File System", "appendfile", {}, function()
    writefile(".PureUNC/appendfile.txt", "he");

    appendfile(".PureUNC/appendfile.txt", "ll");
    appendfile(".PureUNC/appendfile.txt", "o");

    assert(readfile(".PureUNC/appendfile.txt") == "hello", "Failed to make changes to the file");
end);

-- Input library

section("<----- Input Library ----->");

test("Input", "isrbxactive", {"isgameactive"});

test("Input", "mouse1click", {});

test("Input", "mouse1press", {});

test("Input", "mouse1release", {});

test("Input", "mouse2click", {});

test("Input", "mouse2press", {});

test("Input", "mouse2release", {});

test("Input", "mousemoveabs", {});

test("Input", "mousemoverel", {});

test("Input", "mousescroll", {});

-- Instances

section("<----- Instance Library ----->");

test("Instances", "fireclickdetector", {});

test("Instances", "getcallbackvalue", {});

test("Instances", "getconnections", {});

test("Instances", "getcustomasset", {});

test("Instances", "gethiddenproperty", {});

test("Instances", "sethiddenproperty", {});

test("Instances", "gethui", {});

test("Instances", "getinstances", {});

test("Instances", "getnilinstances", {});

test("Instances", "isscriptable", {});

test("Instances", "setscriptable", {});

-- Metatable

section("<----- Metatable Library ----->");

test("Metatable", "getrawmetatable", {});

test("Metatable", "hookmetamethod", {});

test("Metatable", "getnamecallmethod", {});

test("Metatable", "isreadonly", {});

test("Metatable", "setrawmetatable", {});

test("Metatable", "setreadonly", {});

-- Miscellaneous

section("<----- Miscellaneous ----->");

test("Miscellaneous", "identifyexecutor", {});

test("Miscellaneous", "lz4compress", {});

test("Miscellaneous", "lz4decompress", {});

test("Miscellaneous", "messagebox", {});

test("Miscellaneous", "queue_on_teleport", {"queueonteleport"});

test("Miscellaneous", "request", {"http.request", "http_request"});

test("Miscellaneous", "setclipboard", {"toclipboard"});

test("Miscellaneous", "setfpscap", {});

-- Scripts

section("<----- Scripts Library ----->");

test("Scripts", "getgc", {});

test("Scripts", "getgenv", {});

test("Scripts", "getloadedmodules", {});

test("Scripts", "getloadedmodules", {});

test("Scripts", "getrenv", {});

test("Scripts", "getrunningscripts", {});

test("Scripts", "getscriptbytecode", {"dumpstring"});

test("Scripts", "getscripthash", {});

test("Scripts", "getscripts", {});

test("Scripts", "getsenv", {});

test("Scripts", "getthreadidentity", {"getidentity", "getthreadcontext"});

test("Scripts", "setthreadidentity", {"setidentity", "setthreadcontext"})

-- Drawing

section("<----- Drawing Library ----->");

test("Drawing", "Drawing", {});

test("Drawing", "Drawing.New", {});

test("Drawing", "Drawing.Fonts", {});

test("Drawing", "isrenderobj", {});

test("Drawing", "getrenderproperty", {});

test("Drawing", "setrenderproperty", {});

test("Drawing", "cleardrawcache", {});

-- Socket

section("<----- Socket Library ----->");

test("Socket", "WebSocket.connect", {});

-- Begin Test

beginTest();
