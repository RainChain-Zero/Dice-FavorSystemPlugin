--[[
    @author 慕北_Innocent(RainChain)
    @version 1.0(Beta)
    @Created 2021/12/05 00:04
    @Last Modified 2021/12/13 13:59
    ]]

msg_order={}

package.path="/home/container/Dice3349795206/plugin/Story/?.lua"
require "Story"
require "Story0"

--todo 主调入口
function StoryMain(msg)
    local Reply="系统：出现未知错误，请报告系统管理员"
    local StoryNormal=getUserConf(msg.fromQQ,"StoryReadNow",-1)
    local StorySpecial=getUserConf(msg.fromQQ,"SpecialReadNow",-1)

    --未进入剧情模式不触发
    if(StoryNormal+StorySpecial==-2)then
        return "您未进入任何剧情模式哦~"
    end

    --必须在小窗下进行
    if(msg.fromGroup~="0")then
        return "茉莉..茉莉可不想在人多的地方和你分享这些哦（脸红）"
    end

    --? 判断具体剧情
    if(StoryNormal~=-1)then
        if(StoryNormal==0)then
            Reply=StoryZero(msg)
        end
    else
        if(StorySpecial==0)then
            
        end
    end
    return Reply
end
msg_order[".f"]="StoryMain"

--todo 剧情入口点
EntryStoryOrder="进入剧情"
function EnterStory(msg)
    --清空之前所有操作
    Init(msg)
    local Story=string.match(msg.fromMsg,"[%s]*(.*)",#EntryStoryOrder+1)
    if(Story==nil or Story=="")then
        return "请输入章节名哦~"
    end
    if(Story=="序章")then
        local favor=getUserConf(msg.fromQQ,"好感度",0)
        if(favor<1000)then
            return "茉莉暂时还不想和{nick}分享这些呢..这是茉莉的小秘密哦~"
        end
        setUserConf(msg.fromQQ,"StoryReadNow",0)
        setUserConf(msg.fromQQ,"SpecialReadNow",-1)
    elseif(Story=="元旦特典")then

        --! Alpha Ver
        if(msg.fromQQ=="3032902231" or msg.fromQQ=="2677409596")then
            setUserConf(msg.fromQQ,"SpecialReadNow",0)
            setUserConf(msg.fromQQ,"StoryReadNow",-1)
        end

    end
    setUserConf(msg.fromQQ,"MainIndex",1)
    setUserConf(msg.fromQQ,"Option",0)
    return "您已进入剧情模式『"..Story.."』,请在小窗模式下输入.f一步一步进行哦~"
end
msg_order[EntryStoryOrder]="EnterStory"

--todo 配置初始化
function Init(msg)
    setUserConf(msg.fromQQ,"MainIndex",1)
    setUserConf(msg.fromQQ,"Option",0)
    setUserConf(msg.fromQQ,"Choice",0)
    setUserConf(msg.fromQQ,"StoryReadNow",-1)
    setUserConf(msg.fromQQ,"SpecialReadNow",-1)
    setUserConf(msg.fromQQ,"ChoiceSelected0",0)
end


--todo 选项选择
function Choose(msg)
    local Option =getUserConf(msg.fromQQ,"Option",0)
    local StoryNormal=getUserConf(msg.fromQQ,"StoryReadNow",-1)
    local StorySpecial=getUserConf(msg.fromQQ,"SpecialReadNow",-1)
    local Reply
   --未进入任何剧情模式
    if(StoryNormal+StorySpecial==-2)then
       return ""
    end
   --没有任何选项
    if(Option==0)then
        return "您现在还不能选择任何选项哦~"
    end
    
    --匹配选项
    local res=string.match(msg.fromMsg,"[%s]*(%d)",string.find(msg.fromMsg,"选择")+1)
    if(res==nil or res=="" or res*1<1 or res*1>3)then
        return "您必须输入一个有效的选项数字哦~"
    end

    --todo 不同章节一一处理
    if(StoryNormal~=-1)then
        if(StoryNormal==0)then
            Reply=StoryZeroChoose(msg,res)
        end
    else
        if(StorySpecial==0)then
            
        end
    end
    return Reply
end
msg_order["选择"]="Choose"
