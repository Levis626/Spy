--[[
 Synax Spy - Enhanced Edition
]]
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local CoreGui=game:GetService("CoreGui")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local LP=Players.LocalPlayer

local Config={
 WindowSize=UDim2.new(0,520,0,350),BgColor=Color3.fromRGB(15,17,22),CardBg=Color3.fromRGB(22,25,33),
 TextPrimary=Color3.fromRGB(245,245,245),TextSecondary=Color3.fromRGB(130,135,150),
 AccentColor=Color3.fromRGB(85,170,255),CloseRed=Color3.fromRGB(255,70,70),
 EventColor=Color3.fromRGB(85,255,140),RemoteColor=Color3.fromRGB(180,100,255),MaxLogs=100
}

-- Türkçe: Executor GUI parent fallback'ını döndürür.
local function GuiParent()
 local ok,r=pcall(function() return type(gethui)=="function" and gethui() or CoreGui end)
 return ok and r or CoreGui
end
-- Türkçe: Clipboard API fallback'ını dener.
local function Clipboard(s)
 local f=(type(setclipboard)=="function" and setclipboard) or (type(toclipboard)=="function" and toclipboard)
 if not f then return false end
 return pcall(f,s)
end
-- Türkçe: Executor newcclosure desteğini güvenli kullanır.
local function Closure(f)
 if type(newcclosure)=="function" then local ok,r=pcall(newcclosure,f);if ok then return r end end
 return f
end
-- Türkçe: Caller kontrolünü güvenli yapar.
local function Caller()
 if type(checkcaller)=="function" then local ok,r=pcall(checkcaller);if ok then return r end end
 return false
end
-- Türkçe: Namecall metodunu güvenli okur.
local function Method()
 if type(getnamecallmethod)=="function" then local ok,r=pcall(getnamecallmethod);if ok then return r end end
 return ""
end
-- Türkçe: Tween'i hata vermeden oynatır.
local function Tween(o,t,p)
 pcall(function() TweenService:Create(o,t,p):Play() end)
end
-- Türkçe: Köşe yuvarlatması ekler.
local function Corner(o,n)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,n or 6);c.Parent=o;return c end

-- Türkçe: Instance için okunabilir erişim yolu üretir.
local function InstancePath(v)
 if typeof(v)~="Instance" then return "nil" end
 if v==game then return "game" end
 local a,cur={},v
 while cur and cur~=game do table.insert(a,1,cur);cur=cur.Parent end
 if cur~=game then return "nil --[[Instance: "..v:GetFullName().."]]" end
 local out="game"
 for _,x in ipairs(a) do
  if x.Name:match("^[%a_][%w_]*$") then out=out.."."..x.Name else out=out..":FindFirstChild("..string.format("%q",x.Name)..")" end
 end
 return out
end
-- Türkçe: Her desteklenen Roblox tipini Lua temsiline çevirir.
local function Serialize(v,depth,seen)
 depth=depth or 0;seen=seen or {}
 if depth>8 then return "--[[max depth]] nil" end
 local t=typeof(v)
 if v==nil then return "nil"
 elseif t=="string" then return string.format("%q",v)
 elseif t=="number" then if v~=v then return "0/0" elseif v==math.huge then return "math.huge" elseif v==-math.huge then return "-math.huge" end;return tostring(v)
 elseif t=="boolean" then return tostring(v)
 elseif t=="Instance" then return InstancePath(v)
 elseif t=="Vector3" then return string.format("Vector3.new(%.6g, %.6g, %.6g)",v.X,v.Y,v.Z)
 elseif t=="Vector2" then return string.format("Vector2.new(%.6g, %.6g)",v.X,v.Y)
 elseif t=="CFrame" then local q={v:GetComponents()};for i=1,#q do q[i]=string.format("%.6g",q[i]) end;return "CFrame.new("..table.concat(q,", ")..")"
 elseif t=="Color3" then return string.format("Color3.fromRGB(%d, %d, %d)",v.R*255+0.5,v.G*255+0.5,v.B*255+0.5)
 elseif t=="UDim2" then return string.format("UDim2.new(%.6g, %d, %.6g, %d)",v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset)
 elseif t=="UDim" then return string.format("UDim.new(%.6g, %d)",v.Scale,v.Offset)
 elseif t=="EnumItem" then return tostring(v)
 elseif t=="BrickColor" then return "BrickColor.new("..string.format("%q",v.Name)..")"
 elseif t=="table" then
  if seen[v] then return "--[[recursive table]] {}" end;seen[v]=true
  local rows={};for k,x in pairs(v) do local key=type(k)=="string" and k:match("^[%a_][%w_]*$") and k or "["..Serialize(k,depth+1,seen).."]";table.insert(rows,string.rep("    ",depth+1)..key.." = "..Serialize(x,depth+1,seen)..",") end
  seen[v]=nil;table.insert(rows,1,"{");table.insert(rows,string.rep("    ",depth).."}");return table.concat(rows,"\n")
 else return "--[["..t.."]] nil" end
end
-- Remote çağrısı için okunabilir ve kopyalanabilir Lua kodu üretir.
local function BuildCode(remote,kind,args)
 local path="game:GetService("..string.format("%q",remote.Parent and remote.Parent.ClassName=="DataModel" and remote.Name or "")..")"
 pcall(function() path=InstancePath(remote) end)
 local lines={"-- Remote: "..path,"-- Çağrı: "..kind,"-- Zaman: "..os.date("%H:%M:%S"),"","local remote = "..path,"local args = {"}
 for i,v in ipairs(args or {}) do table.insert(lines,string.format("    [%d] = %s,",i,Serialize(v,1,{}))) end
 table.insert(lines,"}");table.insert(lines,"");if kind=="FireServer" then
  table.insert(lines,"remote:FireServer(table.unpack(args))")
elseif kind=="InvokeServer" then
  table.insert(lines,"local result = remote:InvokeServer(table.unpack(args))")
elseif kind=="OnClientEvent" then
  table.insert(lines,"-- Incoming event; connect with:")
  table.insert(lines,"remote.OnClientEvent:Connect(function(...)\n    local args = {...}\n  end)")
end;return table.concat(lines,"\n")
end

local function ExecuteScript()
 local parent=GuiParent();local old=parent:FindFirstChild("SynaxSpy");if old then pcall(old.Destroy,old) end
 local State={logs={},max=100,fire=true,invoke=true,query="",selected=nil,accent=Config.AccentColor,connections={},excludedInstances={},excludedNames={},blockedInstances={},blockedNames={},callCounts={},lastCall={},autoblock=false,logCaller=false,advanced=false,showInfo=true,blockEnabled=true}
 local Gui=Instance.new("ScreenGui");Gui.Name="SynaxSpy";Gui.ResetOnSpawn=false;Gui.IgnoreGuiInset=true;Gui.Parent=parent
 local Pill=Instance.new("TextButton");Pill.Size=UDim2.new(0,150,0,32);Pill.Position=UDim2.new(.5,0,0,10);Pill.AnchorPoint=Vector2.new(.5,0);Pill.BackgroundColor3=Config.BgColor;Pill.BackgroundTransparency=.15;Pill.Text="[ S y n a x  S p y ]";Pill.TextColor3=Config.TextPrimary;Pill.Font=Enum.Font.GothamBold;Pill.TextSize=12;Pill.Visible=false;Pill.AutoButtonColor=false;Pill.Parent=Gui;Corner(Pill,8)
 local Main=Instance.new("Frame");Main.Size=Config.WindowSize;Main.Position=UDim2.new(.5,0,.5,0);Main.AnchorPoint=Vector2.new(.5,.5);Main.BackgroundColor3=Config.BgColor;Main.BorderSizePixel=0;Main.ClipsDescendants=true;Main.Parent=Gui;Corner(Main,10)
 local Bar=Instance.new("Frame");Bar.Size=UDim2.new(1,0,0,35);Bar.BackgroundTransparency=1;Bar.Parent=Main
 local Title=Instance.new("TextLabel");Title.Size=UDim2.new(0,190,1,0);Title.Position=UDim2.new(0,12,0,0);Title.BackgroundTransparency=1;Title.Text="S y n a x  S p y";Title.TextColor3=Config.TextPrimary;Title.Font=Enum.Font.GothamBold;Title.TextSize=13;Title.TextXAlignment=Enum.TextXAlignment.Left;Title.Parent=Bar
 local Status=Instance.new("TextLabel");Status.Size=UDim2.new(0,180,1,0);Status.Position=UDim2.new(0,195,0,0);Status.BackgroundTransparency=1;Status.Text="● SPY";Status.TextColor3=Config.EventColor;Status.Font=Enum.Font.Gotham;Status.TextSize=9;Status.TextXAlignment=Enum.TextXAlignment.Left;Status.Parent=Bar
 local Close=Instance.new("TextButton");Close.Size=UDim2.new(0,38,0,32);Close.Position=UDim2.new(1,-40,0,1);Close.BackgroundTransparency=1;Close.Text="×";Close.TextColor3=Config.CloseRed;Close.Font=Enum.Font.GothamBold;Close.TextSize=20;Close.Parent=Bar
 local Min=Instance.new("TextButton");Min.Size=UDim2.new(0,30,0,30);Min.Position=UDim2.new(1,-72,0,1);Min.BackgroundTransparency=1;Min.Text="-";Min.TextColor3=Config.TextSecondary;Min.Font=Enum.Font.GothamBold;Min.TextSize=18;Min.Parent=Bar
 local TabsBar=Instance.new("Frame");TabsBar.Size=UDim2.new(1,-20,0,28);TabsBar.Position=UDim2.new(0,10,0,35);TabsBar.BackgroundTransparency=1;TabsBar.Parent=Main
 local TL=Instance.new("UIListLayout");TL.FillDirection=Enum.FillDirection.Horizontal;TL.Padding=UDim.new(0,6);TL.Parent=TabsBar
 local Content=Instance.new("Frame");Content.Size=UDim2.new(1,-20,1,-72);Content.Position=UDim2.new(0,10,0,68);Content.BackgroundTransparency=1;Content.Parent=Main
 local Tabs,Pages={},{}
 local ScriptList=nil;local ScriptView=nil;local selectedScript=nil;local RefreshScripts=nil
 -- Türkçe: Sekme ve sayfa oluşturur.
 local function Tab(name,order)
  local b=Instance.new("TextButton");b.Size=UDim2.new(.23,0,1,0);b.BackgroundColor3=Config.CardBg;b.Text=name;b.TextColor3=Config.TextSecondary;b.Font=Enum.Font.GothamMedium;b.TextSize=10;b.LayoutOrder=order;b.AutoButtonColor=false;b.Parent=TabsBar;Corner(b,6)
  local p=Instance.new("Frame");p.Size=UDim2.new(1,0,1,0);p.BackgroundTransparency=1;p.Visible=false;p.Parent=Content;Tabs[name]=b;Pages[name]=p
  b.MouseButton1Click:Connect(function() for _,x in pairs(Tabs)do x.TextColor3=Config.TextSecondary;x.BackgroundColor3=Config.CardBg end;for _,x in pairs(Pages)do x.Visible=false end;b.TextColor3=Config.TextPrimary;b.BackgroundColor3=State.accent;p.Visible=true end);return p
 end
 local Spy=Tab("Spy Monitor",1);local Scripts=Tab("Scripts",2);local Loc=Tab("Location",3);local Settings=Tab("Settings",4);Tabs["Spy Monitor"].TextColor3=Config.TextPrimary;Tabs["Spy Monitor"].BackgroundColor3=State.accent;Spy.Visible=true
 local Search=Instance.new("TextBox");Search.Size=UDim2.new(.35,-5,0,26);Search.BackgroundColor3=Config.CardBg;Search.BorderSizePixel=0;Search.PlaceholderText="Remote ara...";Search.PlaceholderColor3=Config.TextSecondary;Search.Text="";Search.TextColor3=Config.TextPrimary;Search.Font=Enum.Font.Gotham;Search.TextSize=10;Search.ClearTextOnFocus=false;Search.Parent=Spy;Corner(Search,6)
 local List=Instance.new("ScrollingFrame");List.Size=UDim2.new(.35,-5,1,-32);List.Position=UDim2.new(0,0,0,32);List.BackgroundColor3=Config.CardBg;List.BorderSizePixel=0;List.ScrollBarThickness=3;List.Parent=Spy;Corner(List,6)
 local LL=Instance.new("UIListLayout");LL.Padding=UDim.new(0,4);LL.Parent=List;LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()List.CanvasSize=UDim2.new(0,0,0,LL.AbsoluteContentSize.Y+8)end)
 local View=Instance.new("ScrollingFrame");View.Size=UDim2.new(.65,0,.58,0);View.Position=UDim2.new(.35,5,0,0);View.BackgroundColor3=Config.CardBg;View.BorderSizePixel=0;View.ScrollBarThickness=3;View.Parent=Spy;Corner(View,6)
 local Code=Instance.new("TextLabel");Code.Size=UDim2.new(1,-10,0,0);Code.AutomaticSize=Enum.AutomaticSize.Y;Code.Position=UDim2.new(0,5,0,5);Code.BackgroundTransparency=1;Code.Text="-- Event / Remote bekleniyor...";Code.TextColor3=Config.TextPrimary;Code.Font=Enum.Font.Code;Code.TextSize=10;Code.TextXAlignment=Enum.TextXAlignment.Left;Code.TextYAlignment=Enum.TextYAlignment.Top;Code.Parent=View
 local Buttons=Instance.new("ScrollingFrame");Buttons.Size=UDim2.new(.65,0,.50,0);Buttons.Position=UDim2.new(.35,5,.49,0);Buttons.BackgroundTransparency=1;Buttons.BorderSizePixel=0;Buttons.ScrollBarThickness=3;Buttons.CanvasSize=UDim2.new(0,0,0,0);Buttons.Parent=Spy
 local BL=Instance.new("UIGridLayout");BL.CellSize=UDim2.new(.32,0,0,30);BL.CellPadding=UDim2.new(.01,0,0,4);BL.Parent=Buttons
 BL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()Buttons.CanvasSize=UDim2.new(0,0,0,BL.AbsoluteContentSize.Y+6)end)
 local function Btn(text)local b=Instance.new("TextButton");b.Text=text;b.BackgroundColor3=Config.CardBg;b.TextColor3=Config.TextPrimary;b.Font=Enum.Font.GothamMedium;b.TextSize=8;b.AutoButtonColor=false;b.Parent=Buttons;Corner(b,5);return b end
 local Copy=Btn("Copy Code");local CopyRemote=Btn("Copy Remote");local GetScript=Btn("Get Script")
 local FunctionInfo=Btn("Function Info");local DisabledDecompile=Btn("Decompile")
 local ExcludeI=Btn("Exclude (i)");local ExcludeN=Btn("Exclude (n)");local ClearBlacklist=Btn("Clr Blacklist")
 local DisabledBlockI=Btn("Block (i)");local DisabledBlockN=Btn("Block (n)");local DisabledBlockClear=Btn("Clr Blocklist")
 local Autoblock=Btn("Autoblock");local LogCaller=Btn("Logcheckcaller");local Advanced=Btn("Advanced Info")
 local DisableInfo=Btn("Disable Info")

 -- Script tarayıcısı: LocalScript ve ModuleScript envanterini gösterir.
 ScriptList=Instance.new("ScrollingFrame");ScriptList.Size=UDim2.new(.42,0,1,0);ScriptList.BackgroundColor3=Config.CardBg;ScriptList.BorderSizePixel=0;ScriptList.ScrollBarThickness=3;ScriptList.Parent=Scripts;Corner(ScriptList,6)
 local SLL=Instance.new("UIListLayout");SLL.Padding=UDim.new(0,4);SLL.Parent=ScriptList
 SLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()ScriptList.CanvasSize=UDim2.new(0,0,0,SLL.AbsoluteContentSize.Y+8)end)
 ScriptView=Instance.new("ScrollingFrame");ScriptView.Size=UDim2.new(.58,-5,1,0);ScriptView.Position=UDim2.new(.42,5,0,0);ScriptView.BackgroundColor3=Config.CardBg;ScriptView.BorderSizePixel=0;ScriptView.ScrollBarThickness=3;ScriptView.Parent=Scripts;Corner(ScriptView,6)
 local ScriptCode=Instance.new("TextLabel");ScriptCode.Size=UDim2.new(1,-10,0,0);ScriptCode.AutomaticSize=Enum.AutomaticSize.Y;ScriptCode.Position=UDim2.new(0,5,0,5);ScriptCode.BackgroundTransparency=1;ScriptCode.Text="-- Bir script seçin";ScriptCode.TextColor3=Config.TextPrimary;ScriptCode.Font=Enum.Font.Code;ScriptCode.TextSize=10;ScriptCode.TextXAlignment=Enum.TextXAlignment.Left;ScriptCode.TextYAlignment=Enum.TextYAlignment.Top;ScriptCode.Parent=ScriptView
 local ScriptRefresh=Instance.new("TextButton");ScriptRefresh.Size=UDim2.new(0,90,0,28);ScriptRefresh.Position=UDim2.new(1,-95,1,-32);ScriptRefresh.BackgroundColor3=Config.CardBg;ScriptRefresh.Text="Refresh";ScriptRefresh.TextColor3=Config.TextPrimary;ScriptRefresh.Font=Enum.Font.GothamMedium;ScriptRefresh.TextSize=9;ScriptRefresh.AutoButtonColor=false;ScriptRefresh.Parent=Scripts;Corner(ScriptRefresh,5)

 -- Türkçe: Filtre durumuna göre logları gösterir/gizler.
 local function Refresh()local q=string.lower(State.query);for _,l in ipairs(State.logs)do local a=(l.kind=="FireServer" and State.fire) or (l.kind=="InvokeServer" and State.invoke) or l.kind=="OnClientEvent";local excluded=(l.remote and State.excludedInstances[l.remote]) or State.excludedNames[l.name];local b=q=="" or string.find(string.lower(l.name),q,1,true)~=nil;l.button.Visible=a and b and not excluded end end
 -- Türkçe: Maksimum log sayısını uygular ve en eskileri siler.
 local function Trim()while #State.logs>State.max do local l=table.remove(State.logs,1);if l.button then pcall(l.button.Destroy,l.button)end end;Refresh()end
 -- Türkçe: Yakalanan çağrıyı güvenli şekilde listeye ekler.
 local function CaptureCaller()
    local result={name="Unknown",source="Source gizli"}
    pcall(function()
        if type(getcallingscript)=="function" then
            local s=getcallingscript()
            if s then result.name=s:GetFullName();return end
        end
        if type(getscriptclosure)=="function" then
            for lvl=2,10 do
                local info=debug.info(lvl,"f")
                if info and typeof(info)=="Instance" then result.name=info:GetFullName();return end
            end
        end
        if debug and type(debug.info)=="function" then
            for lvl=2,8 do
                local ok,source=pcall(debug.info,lvl,"s")
                if ok and source and source~="" then result.name=tostring(source);return end
            end
        end
    end)
    return result
end

 local function AddLog(remote,kind,args,caller)pcall(function()local code=BuildCode(remote,kind,args);local b=Instance.new("TextButton");b.Size=UDim2.new(1,-6,0,30);b.BackgroundColor3=Color3.fromRGB(30,33,42);b.Text=(State.advanced and ("  ["..kind.."]  "..remote.Name.."\n  Script: "..tostring(caller and caller.name or "Unknown"))) or ("  ["..kind.."]  "..remote.Name);b.TextColor3=Config.TextPrimary;b.Font=Enum.Font.GothamMedium;b.TextSize=8;b.TextXAlignment=Enum.TextXAlignment.Left;b.AutoButtonColor=false;b.Parent=List;Corner(b,4);local line=Instance.new("Frame");line.Size=UDim2.new(0,4,1,0);line.BorderSizePixel=0;line.BackgroundColor3=kind=="FireServer" and Config.EventColor or Config.RemoteColor;line.Parent=b;local l={button=b,code=code,name=remote.Name,kind=kind,remote=remote,caller=caller,time=os.time(),args=args};table.insert(State.logs,l);b.MouseButton1Click:Connect(function()State.selected=l;Code.Text=l.code end);Trim()end)end

 -- Mevcut RemoteEvent / RemoteFunction nesnelerini başlangıçta listeye ekler.
 local function ScanRemotes()
  local seen={}
  local function addRemote(obj)
   if seen[obj] or #State.logs>=State.max then return end
   if not obj:IsA("RemoteEvent") and not obj:IsA("RemoteFunction") then return end
   seen[obj]=true
   local kind=obj:IsA("RemoteEvent") and "RemoteEvent" or "RemoteFunction"
   pcall(function()
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-6,0,30)
    b.BackgroundColor3=Color3.fromRGB(30,33,42)
    b.Text="  [FOUND]  "..obj.Name
    b.TextColor3=Config.TextPrimary;b.Font=Enum.Font.GothamMedium;b.TextSize=8;b.TextXAlignment=Enum.TextXAlignment.Left;b.AutoButtonColor=false;b.Parent=List;Corner(b,4)
    local line=Instance.new("Frame");line.Size=UDim2.new(0,4,1,0);line.BorderSizePixel=0;line.BackgroundColor3=(kind=="RemoteEvent" and Config.EventColor or Config.RemoteColor);line.Parent=b
    local l={button=b,code="-- Found: "..InstancePath(obj).."\n-- ClassName: "..kind,name=obj.Name,kind=(kind=="RemoteEvent" and "FireServer" or "InvokeServer"),remote=obj,caller={name="[inventory]"},time=os.time(),args={}}
    table.insert(State.logs,l)
    b.MouseButton1Click:Connect(function()State.selected=l;Code.Text=l.code end)
    if obj:IsA("RemoteEvent") then
      pcall(function()
        local conn=obj.OnClientEvent:Connect(function(...)
          if not Gui.Parent then return end
          local args={...}
          local caller={name="[OnClientEvent]"}
          AddLog(obj,"OnClientEvent",args,caller)
        end)
        table.insert(State.connections,conn)
      end)
    end
   end)
  end
  pcall(function()for _,obj in ipairs(game:GetDescendants()) do addRemote(obj);if #State.logs>=State.max then break end end end)
  Refresh()
 end
 task.defer(ScanRemotes)
 RefreshScripts=function()
  for _,c in ipairs(ScriptList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
  local count=0;local items={};local first={anticheat=true,cheat=true,security=true,detector=true,ac=true,kick=true,ban=true}
  pcall(function()
   for _,obj in ipairs(game:GetDescendants()) do
    if (obj:IsA("LocalScript") or obj:IsA("ModuleScript")) then
     table.insert(items,obj);count+=1
    end
   end
  end)
  table.sort(items,function(a,b)
   local an=string.lower(a.Name);local bn=string.lower(b.Name)
   local as=false;local bs=false
   for k in pairs(first) do if string.find(an,k,1,true) then as=true end;if string.find(bn,k,1,true) then bs=true end end
   if as~=bs then return as end
   return an<bn
  end)
  for i,obj in ipairs(items) do
   if i>250 then break end
   local tag="";local low=string.lower(obj.Name)
   if low:find("anticheat",1,true) or low:find("anti%-cheat") or low:find("security",1,true) or low:find("detector",1,true) then tag="  [SECURITY?]" end
   local b=Instance.new("TextButton");b.Size=UDim2.new(1,-6,0,31);b.BackgroundColor3=Config.BgColor;b.Text="  ["..obj.ClassName.."]"..tag.."  "..obj.Name;b.TextColor3=Config.TextPrimary;b.Font=Enum.Font.GothamMedium;b.TextSize=8;b.TextXAlignment=Enum.TextXAlignment.Left;b.AutoButtonColor=false;b.Parent=ScriptList;Corner(b,4)
   b.MouseButton1Click:Connect(function()
    selectedScript=obj
    ScriptCode.Text="Name: "..obj.Name.."\nClass: "..obj.ClassName.."\nPath: "..InstancePath(obj)
   end)
  end
  ScriptCode.Text = selectedScript and ("Name: "..selectedScript.Name.."\nClass: "..selectedScript.ClassName.."\nPath: "..InstancePath(selectedScript)) or "-- "..tostring(count).." script bulundu; birini seçin"
 end
 ScriptRefresh.MouseButton1Click:Connect(RefreshScripts)
 task.defer(RefreshScripts)

 Search:GetPropertyChangedSignal("Text"):Connect(function()State.query=Search.Text;Refresh()end)
 Copy.MouseButton1Click:Connect(function()if State.selected then local ok=Clipboard(State.selected.code);Copy.Text=ok and "Copied! ✓" or "Clipboard unavailable";task.delay(1,function()if Copy.Parent then Copy.Text="Copy Code" end end)end end)
 Clear.MouseButton1Click:Connect(function()for _,l in ipairs(State.logs)do pcall(l.button.Destroy,l.button)end;State.logs={};State.selected=nil;Code.Text="-- Event / Remote bekleniyor..."end)

 -- Türkçe: Seçili remote'un tam path'ini panoya kopyalar.
 CopyRemote.MouseButton1Click:Connect(function()if not State.selected then Status.Text=State.showInfo and "Önce bir log seç" or "";return end;local ok,path=pcall(InstancePath,State.selected.remote);if ok then local copied=Clipboard(path);Status.Text=State.showInfo and (copied and "Remote path copied" or "Clipboard unavailable") or "" end end)
 -- Türkçe: Seçili remote'u çağıran script hakkında stack/calling-script bilgisini gösterir.
 GetScript.MouseButton1Click:Connect(function()
    if not State.selected then Status.Text=State.showInfo and "Önce bir log seç" or "";return end
    local scr=nil
    if type(getcallingscript)=="function" then pcall(function() scr=getcallingscript() end) end
    if not scr and type(getscriptclosure)=="function" then
        pcall(function()
            for lvl=2,12 do
                local info=debug.info(lvl,"f")
                if info and typeof(info)=="Instance" and (info:IsA("LocalScript") or info:IsA("ModuleScript")) then scr=info break end
            end
        end)
    end
    if scr then Code.Text="Script: "..scr:GetFullName().."\nParent: "..(scr.Parent and scr.Parent:GetFullName() or "nil")
    else Code.Text="Script bulunamadı" end
end)

 -- Türkçe: Seçili remote hakkında salt-okuma debug bilgisi gösterir.
 FunctionInfo.MouseButton1Click:Connect(function()if not State.selected then Status.Text=State.showInfo and "Önce bir log seç" or "";return end;local l=State.selected;local count=0;local last=l.time;local argc=#(l.args or {});for _,x in ipairs(State.logs)do if x.remote==l.remote then count+=1;if x.time>last then last=x.time;argc=#(x.args or {}) end end end;local parent=l.remote.Parent;Code.Text=table.concat({"Name: "..l.remote.Name,"ClassName: "..l.remote.ClassName,"Full path: "..InstancePath(l.remote),"Logged count: "..tostring(count),"Last call: "..os.date("%H:%M:%S",last),"Last args: "..tostring(argc),"Parent: "..(parent and parent:GetFullName() or "nil")},"\n") end)
 DisabledDecompile.MouseButton1Click:Connect(function()
    local scr=selectedScript
    if not scr and State.selected then
      if type(getcallingscript)=="function" then pcall(function() scr=getcallingscript() end) end
      if not scr and type(getscriptclosure)=="function" then
        pcall(function()
          for lvl=2,12 do
            local info=debug.info(lvl,"f")
            if info and typeof(info)=="Instance" and (info:IsA("LocalScript") or info:IsA("ModuleScript")) then scr=info break end
          end
        end)
      end
    end
    if not scr then ScriptCode.Text="-- Script bulunamadı";Code.Text="-- Script bulunamadı";return end
    local src=nil
    if type(decompile)=="function" then pcall(function() src=decompile(scr) end) end
    if src then
      local out="-- "..scr:GetFullName().."\n\n"..tostring(src):sub(1,12000)
      if selectedScript then ScriptCode.Text=out else Code.Text=out end
    elseif type(getscriptbytecode)=="function" then
      local ok,b=pcall(getscriptbytecode,scr)
      local out=ok and ("-- "..scr:GetFullName().."\n-- Bytecode size: "..tostring(#b).." bytes\n-- Bu executor kaynak kod döndürmüyor.") or "-- Bytecode alınamadı"
      if selectedScript then ScriptCode.Text=out else Code.Text=out end
    else
      local out="-- Bu executor'da decompiler API'si yok\n-- "..scr:GetFullName()
      if selectedScript then ScriptCode.Text=out else Code.Text=out end
    end
 end)

 -- Türkçe: Seçili remote'u instance blacklist'e ekler; çağrıyı engellemez.
 ExcludeI.MouseButton1Click:Connect(function()if not State.selected then Status.Text=State.showInfo and "Önce bir log seç" or "";return end;State.excludedInstances[State.selected.remote]=true;Refresh();Status.Text=State.showInfo and "Instance excluded" or "" end)
 -- Türkçe: Seçili remote adını blacklist'e ekler; çağrıyı engellemez.
 ExcludeN.MouseButton1Click:Connect(function()if not State.selected then Status.Text=State.showInfo and "Önce bir log seç" or "";return end;State.excludedNames[State.selected.name]=true;Refresh();Status.Text=State.showInfo and "Name excluded" or "" end)
 -- Blacklist tablolarını temizler.
 ClearBlacklist.MouseButton1Click:Connect(function()State.excludedInstances={};State.excludedNames={};Refresh();Status.Text=State.showInfo and "Blacklist cleared" or "" end)
 -- Block listelerini yönetir ve hook tarafında uygulanır.
 DisabledBlockI.MouseButton1Click:Connect(function()if not State.selected then Status.Text=State.showInfo and "Önce bir log seç" or "";return end;State.blockedInstances[State.selected.remote]=true;Refresh();Status.Text=State.showInfo and ("Blocked: "..State.selected.name) or "" end)
 DisabledBlockN.MouseButton1Click:Connect(function()if not State.selected then Status.Text=State.showInfo and "Önce bir log seç" or "";return end;State.blockedNames[State.selected.name]=true;Refresh();Status.Text=State.showInfo and ("Blocked name: "..State.selected.name) or "" end)
 DisabledBlockClear.MouseButton1Click:Connect(function()State.blockedInstances={};State.blockedNames={};State.callCounts={};State.lastCall={};Status.Text=State.showInfo and "Blocklist cleared" or "" end)
 -- Türkçe: Belirli çağrı sıklığına ulaşan remote adını otomatik block listesine ekler.

 -- Türkçe: checkcaller() true olan çağrıların da debug loguna alınmasını açar/kapatır.
 local function ToggleButton(button,key,label)
    local function update()
        local value=State[key]
        button.BackgroundColor3=value and State.accent or Config.CardBg
        button.TextColor3=value and Config.TextPrimary or Config.TextSecondary
        button.Text=label..(value and " • ON" or " • OFF")
    end
    update()
    button.MouseButton1Click:Connect(function()
        State[key]=not State[key]
        update()
        if key=="advanced" then
            for _,l in ipairs(State.logs)do
                l.button.Text=(State.advanced and ("  ["..l.kind.."]  "..l.name.."\n  Script: "..tostring(l.caller and l.caller.name or "Unknown"))) or ("  ["..l.kind.."]  "..l.name)
            end
        end
        if key=="autoblock" then
            Status.Text=State.showInfo and (State.autoblock and "Autoblock AÇIK" or "Autoblock KAPALI") or ""
        end
    end)
end
ToggleButton(LogCaller,"logCaller","Logcheckcaller")
ToggleButton(Advanced,"advanced","Advanced Info")
ToggleButton(Autoblock,"autoblock","Autoblock")

 -- Türkçe: Status bilgi yazılarını açıp kapatır.
 DisableInfo.MouseButton1Click:Connect(function()
    State.showInfo=not State.showInfo
    DisableInfo.BackgroundColor3=State.showInfo and State.accent or Config.CardBg
    DisableInfo.TextColor3=State.showInfo and Config.TextPrimary or Config.TextSecondary
    DisableInfo.Text=State.showInfo and "Disable Info • OFF" or "Disable Info • ON"
    Status.Text=State.showInfo and "● HOOK ACTIVE" or ""
end)

 -- Türkçe: Location sayfasını hazırlar; konum güncellemesi 0.1 saniyedir.
 local Card=Instance.new("Frame");Card.Size=UDim2.new(1,0,0,140);Card.Position=UDim2.new(0,0,0,10);Card.BackgroundColor3=Config.CardBg;Card.BorderSizePixel=0;Card.Parent=Loc;Corner(Card,8)
 local PT=Instance.new("TextLabel");PT.Size=UDim2.new(1,-20,0,30);PT.Position=UDim2.new(0,10,0,10);PT.BackgroundTransparency=1;PT.Text="Player Location";PT.TextColor3=Config.TextPrimary;PT.Font=Enum.Font.GothamBold;PT.TextSize=12;PT.TextXAlignment=Enum.TextXAlignment.Left;PT.Parent=Card
 local Pos=Instance.new("TextLabel");Pos.Size=UDim2.new(1,-20,0,50);Pos.Position=UDim2.new(0,10,0,55);Pos.BackgroundTransparency=1;Pos.Text="X: 0.00 | Y: 0.00 | Z: 0.00";Pos.TextColor3=Config.TextPrimary;Pos.Font=Enum.Font.Code;Pos.TextSize=13;Pos.TextXAlignment=Enum.TextXAlignment.Left;Pos.Parent=Card
 local acc=0;State.connections.loc=RunService.Heartbeat:Connect(function(dt)acc+=dt;if acc<.1 then return end;acc=0;pcall(function()local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart");if r then local p=r.Position;Pos.Text=string.format("X: %.2f | Y: %.2f | Z: %.2f",p.X,p.Y,p.Z)end end)end)

 -- Türkçe: Ayarlar sayfasındaki checkbox oluşturur.
 local SL=Instance.new("UIListLayout");SL.Padding=UDim.new(0,6);SL.Parent=Settings
 local ST=Instance.new("TextLabel");ST.Size=UDim2.new(1,0,0,30);ST.BackgroundTransparency=1;ST.Text="Spy Settings";ST.TextColor3=Config.TextPrimary;ST.Font=Enum.Font.GothamBold;ST.TextSize=13;ST.TextXAlignment=Enum.TextXAlignment.Left;ST.Parent=Settings
 local function Check(text,value,color,cb)local b=Instance.new("TextButton");b.Size=UDim2.new(1,-10,0,30);b.BackgroundColor3=Config.CardBg;b.TextColor3=Config.TextPrimary;b.Font=Enum.Font.GothamMedium;b.TextSize=10;b.TextXAlignment=Enum.TextXAlignment.Left;b.AutoButtonColor=false;b.Parent=Settings;Corner(b,5);local v=value;local function up()b.Text=(v and "  ✓ " or "  □ ")..text end;up();b.MouseButton1Click:Connect(function()v=not v;up();cb(v)end);return b end
 Check("FireServer göster",true,Config.EventColor,function(v)State.fire=v;Refresh()end);Check("InvokeServer göster",true,Config.RemoteColor,function(v)State.invoke=v;Refresh()end)
 local Limit=Instance.new("TextBox");Limit.Size=UDim2.new(1,-10,0,34);Limit.BackgroundColor3=Config.CardBg;Limit.BorderSizePixel=0;Limit.Text="100";Limit.PlaceholderText="Max log (1-100)";Limit.TextColor3=Config.TextPrimary;Limit.Font=Enum.Font.Gotham;Limit.TextSize=10;Limit.ClearTextOnFocus=false;Limit.Parent=Settings;Corner(Limit,5);Limit.FocusLost:Connect(function()local n=tonumber(Limit.Text);State.max=n and math.clamp(math.floor(n),1,100) or State.max;Limit.Text=tostring(State.max);Trim()end)
 local Theme=Instance.new("TextButton");Theme.Size=UDim2.new(1,-10,0,34);Theme.BackgroundColor3=Config.CardBg;Theme.Text="Theme Accent: BLUE";Theme.TextColor3=Config.TextPrimary;Theme.Font=Enum.Font.GothamMedium;Theme.TextSize=10;Theme.AutoButtonColor=false;Theme.Parent=Settings;Corner(Theme,5);Theme.MouseButton1Click:Connect(function()State.accent=State.accent==Config.AccentColor and Color3.fromRGB(180,100,255) or Config.AccentColor;Theme.Text=State.accent==Config.AccentColor and "Theme Accent: BLUE" or "Theme Accent: PURPLE";for n,b in pairs(Tabs)do if Pages[n].Visible then b.BackgroundColor3=State.accent end end end)

 -- Türkçe: Pencereyi ekranda sürükler ve ekran sınırına yakınlaştırır.
 local function Drag(o)local dragging=false;local start,origin;local c
 o.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;start=i.Position;origin=o.Position;c=UIS.InputChanged:Connect(function(x)if dragging and (x.UserInputType==Enum.UserInputType.MouseMovement or x.UserInputType==Enum.UserInputType.Touch)then local d=x.Position-start;o.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)end end)end end)
 o.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false;if c then c:Disconnect();c=nil end end end)
 end
 Drag(Main);Drag(Pill)

 -- Türkçe: Minimize/restore/kapatma animasyonlarını yönetir.
 Min.MouseButton1Click:Connect(function()Tween(Main,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,120,0,20),BackgroundTransparency=1});task.delay(.19,function()if not Gui.Parent then return end;Main.Visible=false;Main.Size=Config.WindowSize;Main.BackgroundTransparency=0;Pill.Visible=true;Pill.Size=UDim2.new(0,0,0,32);Tween(Pill,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,150,0,32)})end)end)
 Pill.MouseButton1Click:Connect(function()Pill.Visible=false;Main.Visible=true;Main.Size=UDim2.new(0,0,0,0);Main.BackgroundTransparency=1;Tween(Main,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Config.WindowSize,BackgroundTransparency=0})end)
 Close.MouseButton1Click:Connect(function()Tween(Main,TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1});task.delay(.21,function()if Gui.Parent then Gui:Destroy()end end)end)
 Gui.AncestryChanged:Connect(function(_,p)if p then return end;for _,c in pairs(State.connections)do pcall(c.Disconnect,c)end;State.connections={}end)

 -- Remote çağrı sıklığını ölçer ve autoblock durumunu yönetir.
 local function ObserveAutoblock(remote)
  if not State.autoblock then return false end
  local blocked=false
  pcall(function()
   local now=tick();local name=remote.Name
   if State.lastCall[name] and now-State.lastCall[name]>5 then State.callCounts[name]=1 else State.callCounts[name]=(State.callCounts[name] or 0)+1 end
   State.lastCall[name]=now
   if State.callCounts[name]>=10 then State.blockedNames[name]=true;State.callCounts[name]=0;blocked=true;Status.Text=State.showInfo and ("Auto-blocked: "..name) or "";task.delay(3,function()if Gui.Parent and State.showInfo then Status.Text="● HOOK ACTIVE" end end) end
  end)
  return blocked or (remote.Name and State.blockedNames[remote.Name]) or false
 end

 -- FireServer/InvokeServer çağrılarını mümkün olan executor hook API'leriyle izler.
 local function InstallHook()
  local installed=false

  -- İlk tercih: hookmetamethod. Bazı executor'lar eski closure'ı döndürmeyebilir; bu yüzden önce fallback old'u almaya çalışırız.
  if type(hookmetamethod)=="function" then
   local previous=nil
   pcall(function()
    local mt=getrawmetatable and getrawmetatable(game)
    if mt then previous=mt.__namecall end
   end)
   local ok,ret=pcall(function()
    return hookmetamethod(game,"__namecall",Closure(function(self,...)
      local m=Method()
      if Gui.Parent and (m=="FireServer" or m=="InvokeServer") then
        if State.blockedInstances[self] or (self.Name and State.blockedNames[self.Name]) then return nil end
        if ObserveAutoblock(self) then return nil end
        if not State.excludedInstances[self] and not (self.Name and State.excludedNames[self.Name]) then
          if not (Caller() and not State.logCaller) then AddLog(self,m,{...},CaptureCaller()) end
        end
      end
      local old=ret or previous
      if type(old)=="function" then return old(self,...) end
      return nil
    end))
   end)
   if ok then installed=true end
  end

  -- Fallback: getrawmetatable / setreadonly.
  if not installed and type(getrawmetatable)=="function" then
   local ok=pcall(function()
    local mt=getrawmetatable(game)
    local old=mt.__namecall
    if type(setreadonly)=="function" then setreadonly(mt,false)
    elseif type(make_writeable)=="function" then make_writeable(mt) end
    mt.__namecall=Closure(function(self,...)
      local m=Method()
      if not Gui.Parent then return old(self,...) end
      if m~="FireServer" and m~="InvokeServer" then return old(self,...) end
      if State.blockedInstances[self] or (self.Name and State.blockedNames[self.Name]) then return nil end
      if ObserveAutoblock(self) then return nil end
      if not State.excludedInstances[self] and not (self.Name and State.excludedNames[self.Name]) then
        if not (Caller() and not State.logCaller) then AddLog(self,m,{...},CaptureCaller()) end
      end
      return old(self,...)
    end)
    if type(setreadonly)=="function" then setreadonly(mt,true)
    elseif type(make_readonly)=="function" then make_readonly(mt) end
   end)
   if ok then installed=true end
  end

  Status.Text=installed and (State.showInfo and "● HOOK ACTIVE" or "") or "● HOOK FAILED"
  Status.TextColor3=installed and Config.EventColor or Config.CloseRed
  return installed
 end
 -- Türkçe: Mobil ekranlarda pencere boyutunu otomatik küçültür.
 do
  local cam=workspace.CurrentCamera
  local function FitMobile()
   local v=cam and cam.ViewportSize or Vector2.new(800,600)
   local w=math.min(520,math.max(320,math.floor(v.X*0.92)))
   local h=math.min(350,math.max(260,math.floor(v.Y*0.78)))
   Config.WindowSize=UDim2.new(0,w,0,h)
   Main.Size=Config.WindowSize
  end
  pcall(FitMobile)
  if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(FitMobile) end
 end
 Main.Size=UDim2.new(0,0,0,0);Main.BackgroundTransparency=1;Tween(Main,TweenInfo.new(.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Config.WindowSize,BackgroundTransparency=0});task.defer(function()pcall(InstallHook)end)
end

local ok,err=pcall(ExecuteScript)
if not ok then warn("[Synax Spy] Başlatma hatası:",err) end
