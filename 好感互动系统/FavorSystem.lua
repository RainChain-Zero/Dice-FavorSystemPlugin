---@diagnostic disable: lowercase-global
package.path = getDiceDir() .. "/plugin/ReplyAndDescription/?.lua"
require "favorReply"
require "itemDescription"
package.path = getDiceDir() .. "/plugin/IO/?.lua"
require "IO"
package.path = getDiceDir() .. "/plugin/handle/?.lua"
require "prehandle"
require "favorhandle"
require "showfavorhandle"
require "CustomizedReply"
require "CalibrationSystem"
msg_order = {}

-- 各类上限
today_food_limit = 3 -- 单日喂食次数上限
today_morning_limit = 1 -- 单日早安好感增加次数上限
today_night_limit = 1 -- 每日晚安好感增加次数上限
today_noon_limit = 1 -- 每日午安上限
today_hug_limit = 1 -- 每日拥抱加好感次数上限
today_touch_limit = 1 -- 每日摸头加好感次数上限
today_lift_limit = 1 -- 每日举高高加好感次数上限
today_kiss_limit = 1 -- 每日kiss加好感次数上限
today_hand_limit = 1 -- 每日牵手加好感次数上限
today_face_limit = 1 -- 每日捏/揉脸加好感次数上限
today_suki_limit = 1 -- 每日喜欢加好感次数上限
today_love_limit = 1 -- 每日爱加好感次数上限
today_interaction_limit = 3 -- 每日"互动-部位"增加好感次数上限
today_cute_limit = 1
today_tietie_limit = 1
today_cengceng_limit = 1
flag_food = 0 -- 用于标记多次喂食只回复一次
cnt = 0 -- 用户输入的喂食次数
-- 时间系统
hour = os.date("*t").hour * 1
minute = os.date("%M") * 1
month = os.date("%m") * 1
day = os.date("%d") * 1
year = os.date("%Y") * 1

function topercent(num)
    if (num == nil) then
        return ""
    end
    return string.format("%.2f", num / 100)
end

function add_favor_food(msg, favor, affinity)
    -- 随机好感上升,低好感用户翻倍
    if (favor <= 1500) then
        return ModifyFavorChangeGift(msg, favor, ranint(30, 50), affinity, false)
    elseif (favor <= 4000) then
        return ModifyFavorChangeGift(msg, favor, ranint(20, 30), affinity, false)
    elseif (favor <= 10000) then
        return ModifyFavorChangeGift(msg, favor, ranint(15, 20), affinity, false)
    else
        return ModifyFavorChangeGift(msg, favor, ranint(20, 30), affinity, false)
    end
end
function add_gift_once() -- 单次计数上升
    return 5
    -- return ranint(1,10)
end

-- 下限黑名单判定
function blackList(msg)
    local favor = GetUserConf("favorConf", msg.fromQQ, "好感度", 0)
    if (favor <= -200 and favor > -500) then
        sendMsg("Warning:检测到你的好感度过低，即将触发机体下限保护机制！", msg.gid or 0, msg.fromQQ)
    end
    if (favor < -500) then
        sendMsg("Warning:检测到用户" .. msg.fromQQ .. "触发好感下限" .. "在群" .. msg.gid, 801655697, 0)
        eventMsg(".group " .. msg.gid .. " ban " .. msg.fromQQ .. " " .. tostring(-favor), msg.gid, getDiceQQ())
        return "已触发！"
    end
    return ""
end

function rcv_food(msg)
    -- rude值判定是否接受喂食
    local preReply = preHandle(msg)
    if (preReply ~= nil) then
        return preReply
    end
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    -- 匹配喂食的次数
    if (cnt == 0) then
        cnt = string.match(msg.fromMsg, "[%s]*(%d+)", #food_order + 1)
        if (cnt == nil or cnt == "") then
            cnt = 1
        else
            cnt = cnt * 1
        end
    end
    if (cnt >= 4 or cnt < 0) then
        return "参数有误请重新输入哦~"
    end
    -- 判定当日上限
    local today_gift = GetUserToday(msg.fromQQ, "gifts", 0)
    if (today_gift >= today_food_limit) then
        return "对不起{nick}，茉莉今天...想换点别的口味呢呜QAQ"
    end
    -- 计算今日/累计投喂，存取在骰娘用户记录上
    local DiceQQ = 3349795206
    local gift_add = add_gift_once()
    local self_today_gift = getUserToday(DiceQQ, "gifts", 0) + gift_add * cnt
    setUserToday(DiceQQ, "gifts", self_today_gift)
    --! 骰娘总次数采用Dice!函数
    local self_total_gift = getUserConf(DiceQQ, "gifts", 0) + gift_add * cnt
    setUserConf(DiceQQ, "gifts", self_total_gift)
    -- 循环调用
    while (cnt > 0) do
        local favor_ori, favor_add, calibration_message = favor, 0, nil
        favor_add, calibration_message = add_favor_food(msg, favor_ori, affinity)
        if (calibration_message ~= nil) then
            return calibration_message
        end
        today_gift = today_gift + 1
        SetUserToday(msg.fromQQ, "gifts", today_gift)
        if (today_gift > today_food_limit) then
            break
        end
        favor = favor_ori + favor_add
        -- SetUserConf("favorConf", msg.fromQQ, "好感度", favor)
        favor, affinity = CheckFavor(msg.fromQQ, favor_ori, favor, affinity)
        cnt = cnt - 1
    end
    return "你眼前一黑，手中的食物瞬间消失，再看的时候，眼前的烧酒口中还在咀嚼着什么，扭头躲开了你的目光\n今日已收到投喂" ..
        topercent(self_today_gift) .. "kg\n累计投喂" .. topercent(self_total_gift) .. "kg"
end
food_order = "喂食茉莉"
msg_order[food_order] = "rcv_food"

function show_favor(msg)
    local favor, cohesion, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "cohesion", "affinity"}, {0, 0, 0})
    local state = ShowFavorHandle(msg, favor, affinity)
    local header =
        "[CQ:image,url=http://q1.qlogo.cn/g?b=qq&nk=" ..
        msg.fromQQ .. "&s=640]\n\n亲密度：" .. cohesion .. " | 亲和度：" .. affinity .. " | " .. state
    if (favor < 3000) then
        return header ..
            "对{nick}的好感度只有" ..
                favor .. "，要加油哦~\n茉莉...可是很期待{sample:我们之间能发生什么故事的哦？|你的表现的哦？|你能...（摇头），不，不，没什么|的哦，可这次...茉莉能做好吗}"
    elseif (favor < 6000) then
        return header ..
            "对{nick}的好感度有" .. favor .. "\n{sample:还真是发生了不少事情呢，对吧？~|茉莉要好好记下和你在一起的点点滴滴|最近对茉莉的照顾...我很感激...能不能...}"
    elseif (favor < 10000) then
        return header ..
            "好感度到" ..
                favor .. "了~\n{sample:有时候我会想，说不定真能...嗯嗯？没，我什么都没说，对吧对吧|你总能给茉莉带来很多快乐呢|最近茉莉总有点心神不宁...算了不想了，反正和你在一起就好啦~}"
    else
        return header ..
            "对{nick}的好感度已经有" ..
                favor ..
                    "了,以后也要永远在一起哦~\n{sample:真是的...明明...还要确认一下感情吗（嘟嘴）|茉莉当初没有想到，你会一直 一直陪在茉莉身边...|茉莉觉得，只要和你一直走下去，一定能抓住属于我们的未来的吧？|遇见你之后，我才明白，原来回忆是这么让人快乐和温暖的事|那些独自做不到的事，就让我们一起来把握吧|总感觉，只有和你在一起，茉莉才能看到曾经看不见的『可能性』呢}"
    end
end
msg_order["茉莉好感"] = "show_favor"

-- 早安问候互动程序
function rcv_Ciallo_morning(msg)
    -- 每天第一次早安加5好感度
    local preReply = preHandle(msg)
    if (preReply ~= nil) then
        return preReply
    end
    local today_morning = GetUserToday(msg.fromQQ, "morning", 0)
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    local favor_ori = favor
    today_morning = today_morning + 1
    SetUserToday(msg.fromQQ, "morning", today_morning)
    -- 用于判定成功/失败，增加校准
    local t1, t2, t3, calibration_message = ModifyLimit(msg, favor, affinity)
    if (calibration_message ~= nil) then
        return calibration_message
    end
    -- 其他用户判定
    if (hour >= 5 and hour <= 10) then
        SetUserToday(msg.fromQQ, "morning", today_morning + 1)
        local succ, left_limit, right_limit, calibration_message1 = ModifyLimit(msg, favor, affinity)
        if (calibration_message1 ~= nil) then
            return calibration_message1
        end
        if (succ == false) then
            return "诶？早上好...那我先去准备早饭，有点心不在焉？不不，没有的事"
        end
        local favor_now = favor + ModifyFavorChangeNormal(msg, favor, 5, affinity, true)
        if (today_morning <= 1) then
            -- SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            CheckFavor(msg.fromQQ, favor_ori, favor_now, affinity)
        end
        if (favor < 0) then
            return table_draw(reply_ciallo_lowest)
        elseif (favor < ranint(1500 - left_limit, 1500 + right_limit)) then
            return table_draw(reply_morning_less)
        elseif (favor < ranint(4500 - left_limit, 4500 + right_limit)) then
            return table_draw(reply_morning_low)
        elseif (favor < ranint(6000 - left_limit, 6000 + right_limit)) then
            return table_draw(reply_morning_high)
        else
            return table_draw(reply_morning_highest)
        end
    elseif (hour == 23 or (hour >= 0 and hour <= 2)) then
        return table_draw(relpy_morning_nightWrong)
    elseif (hour >= 11 and hour <= 15) then
        return table_draw(reply_morning_afternoonWrong)
    else
        return table_draw(reply_morning_normalWrong)
    end
end
-- 可能的早安问候池(前缀匹配)
msg_order["早上好茉莉"] = "rcv_Ciallo_morning"
msg_order["茉莉酱早"] = "rcv_Ciallo_morning"
msg_order["早啊茉莉"] = "rcv_Ciallo_morning"
msg_order["茉莉早"] = "rcv_Ciallo_morning"
msg_order["早上好啊茉莉"] = "rcv_Ciallo_morning"
msg_order["早上好哟茉莉"] = "rcv_Ciallo_morning"
msg_order["早安茉莉"] = "rcv_Ciallo_morning"

-- 爱酱特殊问候关键词触发程序
function rcv_Ciallo_morning_master(msg)
    local today_morning = GetUserToday(msg.fromQQ, "morning", 0)
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    -- 关键词匹配
    local judge =
        msg.fromMsg == "早" or string.find(msg.fromMsg, "早上好", 1) ~= nil or string.find(msg.fromMsg, "早啊", 1) ~= nil or
        string.find(msg.fromMsg, "早呀", 1) ~= nil or
        string.find(msg.fromMsg, "早安", 1) ~= nil or
        string.find(msg.fromMsg, "早哟", 1) ~= nil
    local special_judge = string.find(msg.fromMsg, "茉莉", 1) == nil
    today_morning = today_morning + 1
    SetUserToday(msg.fromQQ, "morning", today_morning)
    if (judge and special_judge) then
        if (favor >= 1200) then
            if (hour >= 5 and hour <= 10) then
                return "诶诶诶{nick}早上好！今天是来找茉莉玩的吗？"
            else
                return "唔...{nick}难道是在和另一个自己对话吗...因为现在怎么看都不是早上的样子..."
            end
        end
    end
end
msg_order["早"] = "rcv_Ciallo_morning_master"

-- 午安问候程序（不触发好感事件）
function rcv_Ciallo_afternoon(msg)
    local preReply = preHandle(msg)
    if (preReply ~= nil) then
        return preReply
    end
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    local today_noon = GetUserToday(msg.fromQQ, "noon", 0)
    local favor_ori = favor
    if (favor < -600) then
        return ""
    end
    if (hour > 7 and hour < 11) then
        return "诶..可现在还没到中午诶，是茉莉出故障了吗..."
    end
    if (hour >= 18 or hour <= 6) then
        return "茉莉这次才不会搞错呢！才不会被{nick}这种小花招骗到！外面明明那么黑（指着窗外）"
    end

    SetUserToday(msg.fromQQ, "noon", today_noon + 1)
    local succ, left_limit, right_limit, calibration_message1 = ModifyLimit(msg, favor, affinity)
    if (calibration_message1 ~= nil) then
        return calibration_message1
    end
    if (succ == false) then
        return "啊...？嗯...{nick}午安，很抱歉，能让茉莉一个人待一会吗"
    end
    if (today_noon < today_noon_limit) then
        local favor_now = favor + ModifyFavorChangeNormal(msg, favor, 5, affinity, succ)
        -- SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
        CheckFavor(msg.fromQQ, favor_ori, favor_now, affinity)
    end
    if (favor < 0) then
        return table_draw(reply_ciallo_lowest)
    elseif (favor < ranint(1500 - left_limit, 1500 + right_limit)) then
        return "嗯？要睡午觉了吗，也是，养好精神也很重要呢"
    elseif (favor < ranint(4000 - left_limit, 4000 + right_limit)) then
        return "午安哦，茉莉也有点困了...呼呼呼"
    elseif (favor < ranint(6000 - left_limit, 6000 + right_limit)) then
        return "诶要睡了吗，好、好吧...之后记得找茉莉玩哦"
    else
        return "嗯呐，在你午睡的时候，请让茉莉在一旁陪着你吧#依"
    end
end
msg_order["午安茉莉"] = "rcv_Ciallo_afternoon"
msg_order["茉莉午安"] = "rcv_Ciallo_afternoon"
msg_order["茉莉酱午安"] = "rcv_Ciallo_afternoon"

-- 非指向性午安判断程序
function afternoon_special(msg)
    local favor = GetUserConf("favorConf", msg.fromQQ, "好感度", 0)

    if (favor >= 1200) then
        return "嗯嗯" .. " 午安" .. "，这是茉莉凭个 人 意 愿想对你说的哦~"
    end
end
msg_order["午安"] = "afternoon_special"

-- 指代性中午好
function rcv_Ciallo_noon(msg)
    local preReply = preHandle(msg)
    if (preReply ~= nil) then
        return preReply
    end
    local today_noon = GetUserToday(msg.fromQQ, "noon", 0)
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    local favor_ori = favor
    if hour < 11 or hour > 14 then
        return "咦，现在，是中午？好吧，既然{nick}这么说，那么，中午好！"
    end

    SetUserToday(msg.fromQQ, "today_noon", today_noon + 1)
    local succ, left_limit, right_limit, calibration_message1 = ModifyLimit(msg, favor, affinity)
    if (calibration_message1 ~= nil) then
        return calibration_message1
    end
    if (succ == false) then
        return "中午好。嗯...?你说就没有其他的话了...?"
    end
    if (today_noon < today_noon_limit) then
        local favor_now = favor + ModifyFavorChangeNormal(msg, favor, 5, affinity, succ)
        -- SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
        CheckFavor(msg.fromQQ, favor_ori, favor_now, affinity)
    end
    if (favor < 0) then
        return table_draw(reply_ciallo_lowest)
    elseif (favor <= ranint(1500 - left_limit, 1500 + right_limit)) then
        return "唔，中午好！{nick}，吃过午饭了吗？吃过就赶快去休息吧"
    elseif (favor <= ranint(4500 - left_limit, 4500 + right_limit)) then
        return "中午好呀{nick}——今天过去一半了哦，有什么要做的就抓紧吧"
    elseif (favor <= ranint(6000 - left_limit, 6000 + right_limit)) then
        return "中，中午好{nick}，是有什么要和茉莉说吗！"
    else
        return "中↘午↗好——呀！想睡觉了呢...在那之前#拉衣角 再陪茉莉玩一会吧"
    end
end
msg_order["中午好茉莉"] = "rcv_Ciallo_noon"
msg_order["茉莉中午好"] = "rcv_Ciallo_noon"
msg_order["茉莉酱中午好"] = "rcv_Ciallo_noon"
msg_order["中午好呀茉莉"] = "rcv_Ciallo_noon"
msg_order["中午好啊茉莉"] = "rcv_Ciallo_noon"
msg_order["中午好哟茉莉"] = "rcv_Ciallo_noon"

-- 非指向性中午好
function Ciallo_noon_normal(msg)
    local favor = GetUserConf("favorConf", msg.fromQQ, "好感度", 0)

    if (favor >= 1200) then
        if (hour >= 11 and hour <= 14) then
            return "诶，中午好？是…在和茉莉说吗，应该……是吧"
        end
        return "唔..可现在不是中午哦？不过 茉莉也向你问好哦~#踮起脚尖打招呼"
    end
end
msg_order["中午好"] = "Ciallo_noon_normal"

-- 晚上好
function rcv_Ciallo_evening(msg)
    local preReply = preHandle(msg)
    if (preReply ~= nil) then
        return preReply
    end
    local today_evening = GetUserToday(msg.fromQQ, "evening", 0)
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    local favor_ori = favor
    today_evening = today_evening + 1
    SetUserToday(msg.fromQQ, "evening", today_evening)

    if ((hour >= 18 and hour <= 24) or (hour >= 0 and hour <= 4)) then
        local succ, left_limit, right_limit, calibration_message1 = ModifyLimit(msg, favor, affinity)
        if (calibration_message1 ~= nil) then
            return calibration_message1
        end
        if (succ == false) then
            return "女孩似乎没有理睬你的意思，只是怔怔望着窗外，若有所思×"
        end
        if (today_evening <= 1) then
            local favor_now = favor + ModifyFavorChangeNormal(msg, favor, 5, affinity, succ)
            CheckFavor(msg.fromQQ, favor_ori, favor_now, affinity)
        end
        if favor < 0 then
            return table_draw(reply_ciallo_lowest)
        elseif (favor < ranint(1500 - left_limit, 1500 + right_limit)) then
            return table_draw(reply_evening_less)
        elseif (favor < ranint(4500 - left_limit, 4500 + right_limit)) then
            return table_draw(reply_evening_low)
        elseif (favor < ranint(6000 - left_limit, 6000 + right_limit)) then
            return table_draw(reply_evening_high)
        else
            return table_draw(reply_evening_highest)
        end
    elseif (hour >= 5 and hour <= 12) then
        return table_draw(reply_evening_morningWrong)
    else
        return table_draw(reply_evening_normalWrong)
    end
end
msg_order["茉莉晚上好"] = "rcv_Ciallo_evening"
msg_order["晚上好茉莉"] = "rcv_Ciallo_evening"

-- 晚安问候程序
function rcv_Ciallo_night(msg)
    local preReply = preHandle(msg)
    if (preReply ~= nil) then
        return preReply
    end
    local today_night = GetUserToday(msg.fromQQ, "night", 0)
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    local favor_ori = favor
    today_night = today_night + 1
    SetUserToday(msg.fromQQ, "night", today_night)

    if ((hour >= 21 and hour <= 23) or (hour >= 0 and hour <= 4)) then
        local succ, left_limit, right_limit, calibration_message1 = ModifyLimit(msg, favor, affinity)
        if (calibration_message1 ~= nil) then
            return calibration_message1
        end
        if (succ == false) then
            return "那茉莉就回自己房间了，晚安，明早见"
        end
        if (today_night <= 1) then
            local favor_now = favor + ModifyFavorChangeNormal(msg, favor, 5, affinity, succ)
            -- SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            CheckFavor(msg.fromQQ, favor_ori, favor_now, affinity)
        end
        if favor < 0 then
            return table_draw(reply_ciallo_lowest)
        elseif (favor < ranint(1500 - left_limit, 1500 + right_limit)) then
            return table_draw(reply_night_less)
        elseif (favor < ranint(4500 - left_limit, 4500 + right_limit)) then
            return table_draw(reply_night_low)
        elseif (favor < ranint(6000 - left_limit, 6000 + right_limit)) then
            return table_draw(reply_night_high)
        else
            --! 1298754454 晚安定制
            if msg.fromQQ == "1298754454" then
                return table_draw(merge_reply(reply_night_highest, evening_1298754454))
            end
            return table_draw(reply_night_highest)
        end
    elseif (hour >= 5 and hour <= 11) then
        return table_draw(reply_night_morningWrong)
    elseif (hour >= 12 and hour <= 15) then
        return table_draw(reply_night_afternoonWrong)
    else
        return table_draw(reply_night_normalWrong)
    end
end
-- 可能的晚安问候池(前缀匹配)
msg_order["晚安茉莉"] = "rcv_Ciallo_night"
msg_order["茉莉酱晚安"] = "rcv_Ciallo_night"
msg_order["茉莉晚安"] = "rcv_Ciallo_night"
msg_order["晚安啊茉莉"] = "rcv_Ciallo_night"
msg_order["茉莉哦呀斯密纳塞"] = "rcv_Ciallo_night"
msg_order["茉莉哦呀斯密"] = "rcv_Ciallo_night"

function night_master(msg)
    local favor = GetUserConf("favorConf", msg.fromQQ, "好感度", 0)
    if (favor >= 2000) then
        preHandle(msg)
        if ((hour >= 21 and hour <= 23) or (hour >= 0 and hour <= 4)) then
            return "{sample:晚安哦，虽然不知道为什么，但茉莉想主动对你说晚安~|希望明天我们能依然保持赤诚和热爱|晚安，茉莉会在你身边安心陪你睡着的哦？|晚安~愿你梦中星河烂漫，美好依旧}"
        end
        return "嗯...{nick}现在好像还没到晚安的时间呢..."
    end
end

msg_order["晚安"] = "night_master"

-- 关于晚安、午安的其他表达
function Ciallo_night_2(msg)
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    local succ, left_limit, right_limit, calibration_message1 = ModifyLimit(msg, favor, affinity)
    if (calibration_message1 ~= nil) then
        return calibration_message1
    end
    if (succ == false) then
        return ""
    end

    if (favor < ranint(1000 - left_limit, 1000 + right_limit)) then
        return table_draw(reply_night_less)
    elseif (favor < ranint(2000 - left_limit, 2000 + right_limit)) then
        return table_draw(reply_night_low)
    elseif (favor < ranint(3000 - left_limit, 3000 + right_limit)) then
        return table_draw(reply_night_high)
    else
        return table_draw(reply_night_highest)
    end
end
msg_order["睡了"] = "Ciallo_night_2"
msg_order["我睡了"] = "Ciallo_night_2"

-- 动作交互系统
interaction_order = "茉莉 互动 "
normal_order_old = "茉莉 "
function interaction(msg)
    local preReply = preHandle(msg)
    if (preReply ~= nil) then
        return preReply
    end
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    local today_interaction = GetUserToday(msg.fromQQ, "今日互动", 0)
    local favor_ori = favor
    today_interaction = today_interaction + 1
    SetUserToday(msg.fromQQ, "今日互动", today_interaction)
    local blackReply = blackList(msg)
    if (blackReply ~= "" and blackReply ~= "已触发！") then
        return blackReply
    elseif (blackReply == "已触发！") then
        return ""
    end
    local succ, left_limit, right_limit, calibration_message1 = ModifyLimit(msg, favor, affinity)
    if (calibration_message1) then
        return calibration_message1
    end
    if (succ == false) then
        return "茉莉向后退了一步，并对你比了个“×”的手势×"
    end
    local level
    if (favor <= ranint(1500 - left_limit, 1500 + right_limit)) then
        level = "less"
        SetUserConf(
            "favorConf",
            msg.fromQQ,
            "好感度",
            favor - ModifyFavorChangeNormal(msg, favor, ranint(50, 100), affinity)
        )
    elseif (favor <= ranint(3000 - left_limit, 3000 + right_limit)) then
        level = "low"
        if (today_interaction <= today_interaction_limit) then
            local favor_now = favor + ModifyFavorChangeNormal(msg, favor, ranint(5, 8), affinity)
            -- SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            CheckFavor(msg.fromQQ, favor_ori, favor_now, affinity)
        end
    elseif (favor <= ranint(5000 - left_limit, 5000 + right_limit)) then
        level = "high"
        if (today_interaction <= today_interaction_limit) then
            local favor_now = favor + ModifyFavorChangeNormal(msg, favor, ranint(12, 25), affinity)
            -- SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            CheckFavor(msg.fromQQ, favor_ori, favor_now, affinity)
        end
    else
        level = "highest"
        if (today_interaction <= today_interaction_limit) then
            local favor_now = favor + ModifyFavorChangeNormal(msg, favor, ranint(15, 30), affinity)
            -- SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            CheckFavor(msg.fromQQ, favor_ori, favor_now, affinity)
        end
    end
    local first, second = msg.fromMsg:match("^[%s]*(%S*)[%s]*(%S*)$", #normal_order_old + 1)
    if (first ~= "互动") then
        return ""
    end
    if (second == "") then
        return "茉莉无法解析您的指令哦"
    end
    if (second == "头") then
        second = "head"
    elseif (second == "脸") then
        second = "face"
    elseif (second == "身体") then
        second = "body"
    elseif (second == "脖子") then
        second = "neck"
    elseif (second == "背") then
        second = "back"
    elseif (second == "腰") then
        second = "waist"
    elseif (second == "腿") then
        second = "leg"
    elseif (second == "手") then
        -- 互动 肩膀 定制reply
        second = "hand"
    elseif second:find("肩") then
        return "唔？{nick}累了么？（少女感受着颈间发丝磨蹭的沙沙声与渐渐平静的呼吸，微微侧过脑袋来，声音中流露出直率的关心）茉莉一直在你的身边哦……"
    end
    local flag = second .. "_" .. level
    for k, v in pairs(reply) do
        if (k == flag) then
            return v[ranint(1, #v)]
        end
    end
end
msg_order[interaction_order] = "interaction"

normal_order = "茉莉"
-- 普通问候程序
function _Ciallo_normal(msg)
    local ignore_qq = {959686587}
    --! 千音暂时不回复，以及定制reply
    for _, v in pairs(ignore_qq) do
        if msg.fromQQ * 1 == v then
            return ""
        end
    end
    if (msg.fromQQ == "839968342") then
        if (string.find(msg.fromMsg, "茉莉？") ~= nil or string.find(msg.fromMsg, "茉莉?") ~= nil) then
            return ""
        end
    end
    local str = string.match(msg.fromMsg, "(.*)", #normal_order + 1)
    local deepjudge = {
        "在",
        "——",
        "？",
        "~",
        "！",
        "!",
        "?",
        "吗",
        "呢",
        "茉莉",
        "酱"
    }
    local flag = false
    for k, v in pairs(deepjudge) do
        if (string.find(str, v) ~= nil) then
            flag = true
            break
        end
    end
    if (msg.fromMsg == "茉莉") then
        flag = true
    end
    if (flag == false) then
        return ""
    end
    local favor = GetUserConf("favorConf", msg.fromQQ, "好感度", 0)
    if (favor < -600) then
        return ""
    end

    --! 定制reply
    if msg.fromQQ == "2595928998" then
        reply_main = table_draw(normal_2595928998)
    elseif msg.fromQQ == "751766424" then
        reply_main = table_draw(normal_751766424)
    else
        reply_main = "{sample:嗯哼？茉莉在这哦~Ciallo|诶...是在叫茉莉吗？茉莉茉莉在哦~|我听到了！就是{nick}在叫我！这次一定没有错！}"
    end
end

function action(msg)
    if (Actionprehandle(msg.fromMsg) == false) then
        return ""
    end
    local preReply = preHandle(msg)
    if (preReply ~= nil) then
        reply_main = preReply
        return preReply
    end
    local favor, affinity = GetUserConf("favorConf", msg.fromQQ, {"好感度", "affinity"}, {0, 0})
    local favor_ori, favor_now = favor, favor
    local today_hug,
        today_touch,
        today_lift,
        today_kiss,
        today_hand,
        today_face,
        today_suki,
        today_love,
        today_tietie,
        today_cengceng,
        today_lapPillow =
        GetUserToday(
        msg.fromQQ,
        {
            "hug",
            "touch",
            "lift",
            "kiss",
            "hand",
            "face",
            "suki",
            "love",
            "tietie",
            "cengceng",
            "lapPillow"
        },
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    )

    local blackReply = blackList(msg)

    if (blackReply ~= "" and blackReply ~= "已触发！") then
        return blackReply
    elseif (blackReply == "已触发！") then
        return ""
    end
    local succ, left_limit, right_limit, calibration_message1 = ModifyLimit(msg, favor, affinity)
    if (calibration_message1 ~= nil) then
        reply_main = calibration_message1
        return ""
    end
    --! 灵音定制 蹭蹭
    if (msg.fromQQ == "2595928998" and string.find(msg.fromMsg, "蹭蹭") ~= nil) then
        today_cengceng = today_cengceng + 1
        reply_main = table_draw(cengceng_2595928998)
        SetUserToday(msg.fromQQ, "cengceng", today_cengceng)
        if today_cengceng <= today_cengceng_limit then
            favor_now = favor + ModifyFavorChangeNormal(msg, favor, 20, affinity, succ)
        end
    end
    -- action 抱
    local judge_hug = string.find(msg.fromMsg, "抱", 1) ~= nil
    if (judge_hug) then
        if (succ == false) then
            reply_main = "茉莉突然加快了脚步，你和空气紧紧相拥×"
            SetUserConf("favorConf", msg.fromQQ, "好感度", favor - ModifyFavorChangeNormal(msg, favor, 10, affinity, succ))
            return ""
        end
        today_hug = today_hug + 1
        SetUserToday(msg.fromQQ, "hug", today_hug)

        if (favor <= ranint(1500 - left_limit, 1500 + right_limit)) then
            if (today_hug <= today_hug_limit) then
                SetUserConf(
                    "favorConf",
                    msg.fromQQ,
                    "好感度",
                    favor + ModifyFavorChangeNormal(msg, favor, -90, affinity, succ)
                )
            end
            if favor < 0 then
                reply_main = table_draw(reply_action_lowest)
            else
                reply_main = table_draw(reply_hug_less)
            end
            return
        elseif (favor <= ranint(3000 - left_limit, 3000 + right_limit)) then
            if (today_hug <= today_hug_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 8, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_hug_low)
        elseif (favor <= ranint(6000 - left_limit, 6000 + right_limit)) then
            if (today_hug <= today_hug_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 15, affinity, succ)
            -- SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_hug_high)
        else
            if (today_hug <= today_hug_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 25, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_hug_highest)
        end
    end
    -- action 摸头
    local judge_touch = string.find(msg.fromMsg, "摸头", 1) ~= nil or string.find(msg.fromMsg, "摸摸", 1) ~= nil
    if (judge_touch) then
        if (succ == false) then
            reply_main = "你伸出手去，什么也没碰到，只见她缩了下脖子接一大步走到了你前面×"
            SetUserConf("favorConf", msg.fromQQ, "好感度", favor - ModifyFavorChangeNormal(msg, favor, 10, affinity, succ))
            return ""
        end
        today_touch = today_touch + 1
        SetUserToday(msg.fromQQ, "touch", today_touch)

        if (favor <= ranint(1000 - left_limit, 1000 + right_limit)) then
            if (today_touch <= today_touch_limit) then
                SetUserConf(
                    "favorConf",
                    msg.fromQQ,
                    "好感度",
                    favor + ModifyFavorChangeNormal(msg, favor, -30, affinity, succ)
                )
            end
            if favor < 0 then
                reply_main = table_draw(reply_action_lowest)
            else
                reply_main = table_draw(reply_touch_less)
            end
            return
        elseif (favor <= ranint(2000 - left_limit, 2000 + right_limit)) then
            if (today_touch <= today_touch_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 8, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_touch_low)
        elseif (favor <= ranint(4500 - left_limit, 4500 + right_limit)) then
            if (today_touch <= today_touch_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 12, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_touch_high)
        else
            if (today_touch <= today_touch_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 16, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_touch_highest)
        end
    end

    -- action举高高
    local judge_lift = string.find(msg.fromMsg, "举高", 1) ~= nil
    if (judge_lift) then
        if (succ == false) then
            reply_main = "你就这样顺势把茉莉举了起来...是假的，她好像发现了什么正弯下腰端详着，只有你高举双臂不知道在干什么×"
            SetUserConf("favorConf", msg.fromQQ, "好感度", favor - ModifyFavorChangeNormal(msg, favor, 10, affinity, succ))
            return ""
        end
        today_lift = today_lift + 1
        SetUserToday(msg.fromQQ, "lift", today_lift)

        if (favor <= ranint(1550 - left_limit, 1550 + right_limit)) then
            if (today_lift <= today_lift_limit) then
                SetUserConf(
                    "favorConf",
                    msg.fromQQ,
                    "好感度",
                    favor + ModifyFavorChangeNormal(msg, favor, -80, affinity, succ)
                )
            end
            if favor < 0 then
                reply_main = table_draw(reply_action_lowest)
            else
                reply_main = table_draw(reply_lift_less)
            end
            return
        elseif (favor <= ranint(3200 - left_limit, 3200 + right_limit)) then
            if (today_lift <= today_lift_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 10, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_lift_low)
        elseif (favor <= ranint(6800 - left_limit, 6800 + right_limit)) then
            if (today_lift <= today_lift_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 14, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_lift_high)
        else
            if (today_lift <= today_lift_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 18, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_lift_highest)
        end
    end
    -- action kiss
    local judge_kiss = string.find(msg.fromMsg, "亲", 1) ~= nil
    if (judge_kiss) then
        if (succ == false) then
            reply_main = "正当你鼓起勇气凑近她的脸庞，却被她有力的手给推开了×"
            SetUserConf("favorConf", msg.fromQQ, "好感度", favor - ModifyFavorChangeNormal(msg, favor, 10, affinity, succ))
            return ""
        end
        today_kiss = today_kiss + 1
        SetUserToday(msg.fromQQ, "kiss", today_kiss)

        if (favor <= ranint(2000 - left_limit, 2000 + right_limit)) then
            SetUserConf(
                "favorConf",
                msg.fromQQ,
                "好感度",
                favor + ModifyFavorChangeNormal(msg, favor, -100, affinity, succ)
            )
            if favor < 0 then
                reply_main = table_draw(reply_action_lowest)
            else
                reply_main = table_draw(reply_kiss_less)
            end
            return
        elseif (favor <= ranint(3200 - left_limit, 3200 + right_limit)) then
            SetUserConf(
                "favorConf",
                msg.fromQQ,
                "好感度",
                favor + ModifyFavorChangeNormal(msg, favor, -20, affinity, succ)
            )
            reply_main = table_draw(reply_kiss_low)
            return
        elseif (favor <= ranint(6700 - left_limit, 6700 + right_limit)) then
            if (today_kiss <= today_kiss_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 15, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_kiss_high)
        else
            if (today_kiss <= today_kiss_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 20, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_kiss_highest)
        end
    end
    -- action 牵手
    local judge_hand = string.find(msg.fromMsg, "牵手", 1) ~= nil
    if (judge_hand) then
        if (succ == false) then
            reply_main = "你试探性地触碰了一下她的手，可她却把手缩到胸前，嘴唇微张却没有说话×"
            SetUserConf("favorConf", msg.fromQQ, "好感度", favor - ModifyFavorChangeNormal(msg, favor, 10, affinity, succ))
            return ""
        end
        today_hand = today_hand + 1
        SetUserToday(msg.fromQQ, "hand", today_hand)

        if (favor <= ranint(1200 - left_limit, 1200 + right_limit)) then
            SetUserConf(
                "favorConf",
                msg.fromQQ,
                "好感度",
                favor + ModifyFavorChangeNormal(msg, favor, -40, affinity, succ)
            )
            if favor < 0 then
                reply_main = table_draw(reply_action_lowest)
            else
                reply_main = table_draw(reply_hand_less)
            end
            return
        elseif (favor <= ranint(2800 - left_limit, 2800 + right_limit)) then
            if (today_hand <= today_hand_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 8, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_hand_low)
        elseif (favor <= ranint(5800 - left_limit, 5800 + right_limit)) then
            if (today_hand <= today_hand_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 10, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_hand_high)
        else
            if (today_hand <= today_hand_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 12, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            if msg.fromQQ ~= "3358315232" then
                reply_main = table_draw(reply_hand_highest)
            else
                reply_main = table_draw(merge_reply(reply_hand_highest, hand_3358315232))
            end
        end
    end
    -- action 捏/揉脸
    local judge_face =
        string.find(msg.fromMsg, "捏脸", 1) ~= nil or string.find(msg.fromMsg, "揉脸", 1) ~= nil or
        string.find(msg.fromMsg, "揉揉", 11) ~= nil
    if (judge_face) then
        if (succ == false) then
            reply_main = "你的手还在空中之际，对上了她眨巴眨巴的眼睛，你尴尬地缩回了手×"
            SetUserConf("favorConf", msg.fromQQ, "好感度", favor - ModifyFavorChangeNormal(msg, favor, 10, affinity, succ))
            return ""
        end
        today_face = today_face + 1
        SetUserToday(msg.fromQQ, "face", today_face)

        if (favor <= ranint(1100 - left_limit, 1100 + right_limit)) then
            SetUserConf(
                "favorConf",
                msg.fromQQ,
                "好感度",
                favor + ModifyFavorChangeNormal(msg, favor, -40, affinity, succ)
            )
            if favor < 0 then
                reply_main = table_draw(reply_action_lowest)
            else
                reply_main = table_draw(reply_face_less)
            end
            return
        elseif (favor <= ranint(3200 - left_limit, 3200 + right_limit)) then
            if (today_face <= today_face_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 5, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_face_low)
        elseif (favor <= ranint(6000 - left_limit, 6000 + right_limit)) then
            if (today_face <= today_face_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 10, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_face_high)
        else
            if (today_face <= today_face_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 14, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_face_highest)
        end
    end
    -- 赞美和情感表达系统
    -- 可爱
    local judge_cute =
        string.find(msg.fromMsg, "可爱", 1) ~= nil or string.find(msg.fromMsg, "卡哇伊", 1) ~= nil or
        string.find(msg.fromMsg, "萌", 1) ~= nil or
        string.find(msg.fromMsg, "kawai", 1) ~= nil or
        string.find(msg.fromMsg, "kawayi", 1) ~= nil
    if (judge_cute) then
        local today_cute = GetUserToday(msg.fromQQ, "cute", 0)
        if (succ == false) then
            reply_main = "可爱吗...虽然茉莉不是很明白为什么...×"
        end
        today_cute = today_cute + 1
        SetUserToday(msg.fromQQ, "cute", today_cute)

        if (favor <= ranint(1050 - left_limit, 1050 + right_limit)) then
            if (today_cute <= today_cute_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 8, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_cute_less)
        elseif (favor <= ranint(3000 - left_limit, 3000 + right_limit)) then
            if (today_cute <= today_cute_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 10, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_cute_low)
        elseif (favor <= ranint(4000 - left_limit, 4000 + right_limit)) then
            if (today_cute <= today_cute_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 12, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_cute_high)
        else
            if (today_cute <= today_cute_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 15, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_cute_highest)
        end
    end
    -- express suki
    local judge_suki = string.find(msg.fromMsg, "喜欢", 1) ~= nil or string.find(msg.fromMsg, "suki", 1) ~= nil
    if (judge_suki) then
        if (succ == false) then
            reply_main = "非常感谢{nick}的喜欢×"
        end
        today_suki = today_suki + 1
        SetUserToday(msg.fromQQ, "suki", today_suki)

        if (favor <= ranint(1500 - left_limit, 1500 + right_limit)) then
            reply_main = table_draw(reply_suki_less)
        elseif (favor <= ranint(3500 - left_limit, 3500 + right_limit)) then
            if (today_suki <= today_suki_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 12, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_suki_low)
        elseif (favor <= ranint(5500 - left_limit, 5500 + right_limit)) then
            if (today_suki <= today_suki_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 15, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_suki_high)
        else
            if (today_suki <= today_suki_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 20, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_suki_highest)
        end
    end
    -- express love
    local judge_love = string.find(msg.fromMsg, "爱", 1) ~= nil or string.find(msg.fromMsg, "love", 1) ~= nil
    if (judge_love and not judge_cute) then
        today_love = today_love + 1
        SetUserToday(msg.fromQQ, "love", today_love)
        if (favor <= ranint(1800 - left_limit, 1800 + right_limit)) then
            reply_main = table_draw(reply_love_less)
        elseif (favor <= ranint(4500 - left_limit, 4500 + right_limit)) then
            if (today_love <= today_love_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 15, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_love_low)
        elseif (favor <= ranint(6500 - left_limit, 6500 + right_limit)) then
            if (today_love <= today_love_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 20, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_love_high)
        else
            if (today_love <= today_love_limit) then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 25, affinity, succ)
            --SetUserConf("favorConf", msg.fromQQ, "好感度", favor_now)
            end
            reply_main = table_draw(reply_love_highest)
        end
    end
    local judge_tietie = string.find(msg.fromMsg, "贴贴", 1) ~= nil
    if judge_tietie then
        today_tietie = today_tietie + 1
        SetUserToday(msg.fromQQ, "tietie", today_tietie)
        if favor <= ranint(1500 - left_limit, 1500 + right_limit) then
            favor_now = favor + ModifyFavorChangeNormal(msg, favor, -40, affinity, succ)
            reply_main = table_draw(reply_tietie_less)
        elseif favor <= ranint(3500 - left_limit, 3500 + right_limit) then
            if today_tietie <= today_tietie_limit then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 10, affinity, succ)
            end
            reply_main = table_draw(reply_tietie_low)
        elseif favor <= ranint(5500 - left_limit, 5500 + left_limit) then
            if today_tietie <= today_tietie_limit then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 13, affinity, succ)
            end
            reply_main = table_draw(reply_tietie_high)
        else
            if today_tietie <= today_tietie_limit then
                favor_now = favor + ModifyFavorChangeNormal(msg, favor, 15, affinity, succ)
            end
            if ranint(1, 2) == 1 then
                reply_main = table_draw(reply_tietie_high)
            else
                reply_main = table_draw(reply_tietie_highest)
            end
        end
    end
    if msg.fromMsg:find("膝枕") then
        if favor <= ranint(8000 - left_limit, 8000 + right_limit) then
            favor_now = favor + ModifyFavorChangeNormal(msg, favor, -20, affinity, succ)
            reply_main = "嗯...？{nick}是生病了吧？怎么会说出这样的要求呢？茉莉无法答应哦。"
        elseif GetUserConf("storyConf", msg.fromQQ, "isSpecial5Read", 0) == 0 then
            reply_main = "{nick}想要膝枕吗？现在茉莉有些忙，可以等下次再说吗？\n（解锁条件：阅读剧情『夜』）"
        elseif today_lapPillow >= 1 then
            reply_main = "茉莉刚才不是已经安慰过{nick}了吗？真是的...怎么和小孩子一样啊....好吧，只能再休息一下下哦？"
        else
            today_lapPillow = today_lapPillow + 1
            SetUserToday(msg.fromQQ, "lapPillow", today_lapPillow)
            reply_main = table_draw(reply_lapPillow)
            favor_now = favor + ModifyFavorChangeNormal(msg, favor, 20, affinity, succ)
        end
    end
    CheckFavor(msg.fromQQ, favor_ori, favor_now, affinity)
end

-- 以“茉莉 ”开头代表对象指向 然后搜索匹配相关动作
reply_main = ""
-- 执行函数相应“茉莉”
function action_main(msg)
    if (reply_main ~= "") then
        return reply_main
    end
    action(msg)
    if (reply_main ~= "") then
        return reply_main
    end
    _Ciallo_normal(msg)
    return reply_main
end
msg_order[normal_order] = "action_main"

--! 注册指令
function register(msg)
    setUserConf(msg.fromQQ, "isRegister", 1)
    return "信息已录入...欢迎您，{nick}，希望能和你一起创造美好的回忆~"
end
msg_order["我已阅读并理解茉莉协议，同意接受以上服务条款"] = "register"

function table_draw(tab)
    return tab[ranint(1, #tab)]
end
