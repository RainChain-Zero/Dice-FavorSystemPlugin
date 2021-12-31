--[[
    @author 慕北_Innocent(RainChain)
    @version 1.5(Beta)
    @Created 2021/12/13 09:19
    @Last Modified 2021/12/30 14:45
    ]]
    
--元旦特典 2021.12.13
function SpecialZero(msg)
    local MainIndex,Option,Choice=getUserConf(msg.fromQQ,"MainIndex",1),getUserConf(msg.fromQQ,"Option",0),getUserConf(msg.fromQQ,"Choice",0)
    local ChoiceIndex=getUserConf(msg.fromQQ,"ChoiceIndex",1)
    local favor=getUserConf(msg.fromQQ,"好感度",0)
    local content="系统：出现未知错误，请报告系统管理员"
    if(Option==0)then
        content=Special0[MainIndex];
        if(MainIndex==7)then
            setUserConf(msg.fromQQ,"Option",1)
        elseif(MainIndex==24)then
            setUserConf(msg.fromQQ,"Option",2)
        elseif(MainIndex==35)then
            setUserConf(msg.fromQQ,"Option",3)
        elseif(MainIndex==43)then
            setUserConf(msg.fromQQ,"Option",4)
        end
        MainIndex=MainIndex+1
        setUserConf(msg.fromQQ,"MainIndex",MainIndex)
        return content
    elseif(Option==1)then
        if(Choice==0)then
            return "请选择其中一个选项以推进哦~"
        end
        --记录下一个跳转选项
        setUserConf(msg.fromQQ,"NextOption",2)

        if(Choice==1)then
            MainIndex=8
            content=Special0[MainIndex][ChoiceIndex]
            ChoiceIndex=ChoiceIndex+1
            setUserConf(msg.fromQQ,"ChoiceIndex",ChoiceIndex)
            if(ChoiceIndex>6)then
                OptionNormalInit(msg,11)
            end
        elseif(Choice==2)then
            MainIndex=9
            content=Special0[MainIndex][ChoiceIndex]
            ChoiceIndex=ChoiceIndex+1
            setUserConf(msg.fromQQ,"ChoiceIndex",ChoiceIndex)
            if(ChoiceIndex>12)then
                OptionNormalInit(msg,11)
            end
        elseif(Choice==3)then
            MainIndex=10
            content=Special0[MainIndex][ChoiceIndex]
            ChoiceIndex=ChoiceIndex+1
            setUserConf(msg.fromQQ,"ChoiceIndex",ChoiceIndex)
            if(ChoiceIndex>8)then
                OptionNormalInit(msg,11)
            end
        end
    elseif(Option==2)then
        if(Choice==0)then
            return "请选择其中一个选项以推进哦~"
        end
        --记录下一个跳转选项
        setUserConf(msg.fromQQ,"NextOption",3)

        if(Choice==1)then
            if(favor<3000)then
                return "您的好感度不足哦~为"..favor
            end
            MainIndex=25
            content=Special0[MainIndex][ChoiceIndex]
            ChoiceIndex=ChoiceIndex+1
            setUserConf(msg.fromQQ,"ChoiceIndex",ChoiceIndex)
            if(ChoiceIndex>9)then
                OptionNormalInit(msg,28)
            end
        elseif(Choice==2)then
            if(favor<2000)then
                return "您的好感度不足哦~为"..favor
            end
            MainIndex=26
            content=Special0[MainIndex][ChoiceIndex]
            ChoiceIndex=ChoiceIndex+1
            setUserConf(msg.fromQQ,"ChoiceIndex",ChoiceIndex)
            if(ChoiceIndex>10)then
                OptionNormalInit(msg,28)
            end
        elseif(Choice==3)then
            --进入本选择则不可跳转
            setUserConf(msg.fromQQ,"NextOption",-1)
        
            MainIndex=27
            content=Special0[MainIndex][ChoiceIndex]
            ChoiceIndex=ChoiceIndex+1
            setUserConf(msg.fromQQ,"ChoiceIndex",ChoiceIndex)
            --! 直接结束
            if(ChoiceIndex>7)then
                setUserConf(msg.fromQQ,"isSpecial0Read",1)
                Init(msg);
            end
        end
    elseif(Option==3)then
        if(Choice==0)then
            return "请选择其中一个选项以推进哦~"
        else
            --记录下一个跳转选项
            setUserConf(msg.fromQQ,"NextOption",4)

            setUserConf(msg.fromQQ,"Special0Option3",Choice)
            OptionNormalInit(msg,37)
            return Special0[36]
        end
    elseif(Option==4)then
        if(Choice==0)then
            return "请选择其中一个选项以推进哦~"
        end
        --进入本选择则不可跳转
        setUserConf(msg.fromQQ,"NextOption",-1)

        if(Choice==1)then
            MainIndex=44
            if(ChoiceIndex==5)then
                content=Special0[MainIndex][ChoiceIndex][getUserConf(msg.fromQQ,"Special0Option3",1)]
            else
                content=Special0[MainIndex][ChoiceIndex]
            end
            ChoiceIndex=ChoiceIndex+1
            setUserConf(msg.fromQQ,"ChoiceIndex",ChoiceIndex)
            if(ChoiceIndex>14)then
                --todo 记录用户在给出卡片的前提下结束剧情
                setUserConf(msg.fromQQ,"Special0Flag",1)
                setUserConf(msg.fromQQ,"isSpecial0Read",1)
                Init(msg)
            end
        elseif(Choice==2)then
            MainIndex=45
            content=Special0[MainIndex][ChoiceIndex]
            ChoiceIndex=ChoiceIndex+1
            setUserConf(msg.fromQQ,"ChoiceIndex",ChoiceIndex)
            if(ChoiceIndex>9)then
                setUserConf(msg.fromQQ,"isSpecial0Read",1)
                Init(msg);
            end
        end
    end
    return content
end

function SpecialZeroChoose(msg,res)
    local Option=getUserConf(msg.fromQQ,"Option",0)
    if(Option==4 and res*1==3)then
        return "您必须输入一个有效的选项数字哦~"
    end
    setUserConf(msg.fromQQ,"Choice",res*1)
    return "您选中了选项"..res.." 输入.f以确认选择"
end

function SkipSpecial0(msg)
    local NextOption=getUserConf(msg.fromQQ,"NextOption",1)
    if(NextOption==-1)then
        return "当前所处选项不允许跳转哦？~（选项限制/已经是最后一个选项）"
    end
    local isSpecial0Read=getUserConf(msg.fromQQ,"isSpecial0Read",0)
    if(isSpecial0Read==0)then
        return "初次阅读可不支持跳过哦？"
    end
    OptionNormalInit(msg,1)
    local MAININDEX=
    {
        [1]=7,
        [2]=24,
        [3]=35,
        [4]=43
    }
    setUserConf(msg.fromQQ,"MainIndex",MAININDEX[NextOption])
end