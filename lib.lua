-- Page: ページ
-- Problem: 問題
-- Subproblem: 問題の内の小問
-- Chapter: 章
--
-- 文字列の表示は __tostring() による

Page = {}
Page.__index = Page

-- page.new(2, 4) により "p2--4" のページオブジェクトが作られる
function Page.new(first, last)
  if last == nil then
    return Page.new(first, first)
  end
  local ret = {
    first = first,
    last = last,
  }
  return setmetatable(ret, Page)
end

function Page.fromString(str)
  local nums = {}
  for num in string.gmatch(str, "%d+") do
    table.insert(nums, tonumber(num))
  end
  if #nums ~=1 and #nums ~= 2 then
    error(string.format("Page.fromString(): Failed to parse '%s' as page number(s)! Page number(s) should consist of exactly one or two integers."))
  end
  return Page.new(nums[1], nums[2])
end

function Page.__eq(p, q)
  return p.first == q.first and p.last == q.last
end

function Page:__tostring()
  if self.first == self.last then
    return string.format("p%d", self.first)
  else
    return string.format("p%d–%d", self.first, self.last)
  end
end


Problem = {}
Problem.__index = Problem

-- Problem.new(Page.new(1, 3), "1", 5, true) により問題が作られる．三番目の引数は小問の個数（省略すると 0 となる），四番目の引数は小問を持つかどうか（進捗の出力で用いられる）
-- 内部では小問を持たない場合でも自身を小問の個数にカウントしている，最後の引数は表示の際の処理にのみ用いられる
function Problem.new(page, name, subproblemCount, haveSubproblems)
  if subproblemCount == nil then
    local subproblemCount = 0
  end
  local ret = {
    page = page,
    name = name,
    subproblemCount = subproblemCount,
    subproblemDone = 0,
    haveSubproblems = haveSubproblems,
  }
  return setmetatable(ret, Problem)
end

function Problem:incrementDone()
  self.subproblemDone = self.subproblemDone + 1
end

function Problem:isDone()
  return self.subproblemDone == self.subproblemCount
end

function Problem:doneProportion()
  return self.subproblemDone / self.subproblemCount
end

function Problem:__tostring()
  return self.name
end


Chapter = {}
Chapter.__index = Chapter

-- Chapter.new("第 1 章") により章が作られる．
function Chapter.new(name)
  local ret = {
    name = name,
    pages = {},
    -- キーは tostring(page)
    -- tostring が無いとキーとして上手く働かない
    problems = {},
    problemCount = 0,
  }
  return setmetatable(ret, Chapter)
end

function Chapter:addPage(page)
  if self.problems[tostring(page)] == nil then
    table.insert(self.pages, page)
    self.problems[tostring(page)] = {}
  end
end

function Chapter:addProblem(problem)
  self.problemCount = self.problemCount + 1
  local page = problem.page
  self:addPage(page)
  table.insert(self.problems[tostring(page)], problem)
end

function Chapter:isDone(page)
  if page == nil then
    for _, page in ipairs(self.pages) do
      for _, problem in ipairs(self.problems[tostring(page)]) do
        if not problem:isDone() then
          return false
        end
      end
    end
  else
    for _, problem in ipairs(self.problems[tostring(page)]) do
      if not problem:isDone() then
        return false
      end
    end
  end
  return true
end

-- page が nil なら章全体，そうで無いのならば特定のページのみ
function Chapter:doneProportion(page)
  local sum = 0.0
  local done = 0
  local partial = 0
  local count = 0
  if page == nil then
    count = self.problemCount
    for _, page in ipairs(self.pages) do
      for _, problem in ipairs(self.problems[tostring(page)]) do
        local prop = problem:doneProportion()
        sum = sum + prop
        if problem:isDone() then
          done = done + 1
        elseif prop > 0 then
          partial = partial + 1
        end
      end
    end
  else
    count = #self.problems[tostring(page)]
    for _, problem in ipairs(self.problems[tostring(page)]) do
      local prop = problem:doneProportion()
      sum = sum + prop
      if problem:isDone() then
        done = done + 1
      elseif prop > 0 then
        partial = partial + 1
      end
    end
  end
  if count == 0 then
    return 1.0, 0, 0, 0
  else
    return sum / count, done, partial, count
  end
end

function Chapter:__tostring()
  return self.name
end

function progressTipDarkColor(percentage)
  local color = ""
  if percentage == 100 then
    color = "1f9b03"
  elseif 80 <= percentage then
    color = "039b96"
  elseif 50 <= percentage then
    color = "8c8e02"
  elseif 30 <= percentage then
    color = "b55003"
  else
    color = "a80319"
  end
  return color
end

function progressTipLightColor(percentage)
  local color = ""
  if percentage == 100 then
    color = "46c12a"
  elseif 80 <= percentage then
    color = "2dcec9"
  elseif 50 <= percentage then
    color = "e5e833"
  elseif 30 <= percentage then
    color = "e88133"
  else
    color = "db3047"
  end
  return color
end


function progressTip(obj, page)
  local percentage = 0
  local color = ""
  -- done ではなかったら max 90% とする
  if obj:isDone(page) then
    percentage = 100
  else
    percentage = math.min(math.floor(obj:doneProportion(page) * 10 + 0.5), 9) * 10
  end
  darkColor = progressTipDarkColor(percentage)
  lightColor = progressTipLightColor(percentage)
  darkImg = string.format("<source media=\"(prefers-color-scheme: dark)\" alt=\"%d%%\"  srcset=\"https://img.shields.io/badge/%d%%25-%s\">", percentage, percentage, darkColor)
  lightImg = string.format("<source media=\"(prefers-color-scheme: light)\" alt=\"%d%%\"  srcset=\"https://img.shields.io/badge/%d%%25-%s\">", percentage, percentage, lightColor)
  fallbackImg = string.format("<img alt=\"%d%%\" src=\"https://img.shields.io/badge/%d%%25-%s\">", percentage, percentage, lightColor)
  return string.format("<picture>%s%s%s</picture>", darkImg, lightImg, fallbackImg)
end

function checkbox(flag)
  if flag then
    return "[x]"
  else
    return "[ ]"
  end
end

function progressChapter(stream, chapter)
  local done = chapter:isDone()
  local prop, done, partial, count = chapter:doneProportion(page)
  stream:write(string.format("## %s&nbsp; %s（%d 問 / %d 問 / %d 問）\n\n", progressTip(chapter), chapter, done, partial, count))
  for _, page in ipairs(chapter.pages) do
    local _, done, partial, count = chapter:doneProportion(page)
    stream:write(string.format("### %s&nbsp; %s（%d 問 / %d 問 / %d 問）\n\n", progressTip(chapter, page), page, done, partial, count))
    stream:write("<details>\n<summary>内訳</summary>\n\n<br/>\n\n")
    for _, problem in ipairs(chapter.problems[tostring(page)]) do
      if problem.haveSubproblems then
        stream:write(string.format("- %s %s&nbsp; **%s**（%d / %d）\n", checkbox(problem:isDone()), progressTip(problem), problem, problem.subproblemDone, problem.subproblemCount))
      else
        stream:write(string.format("- %s %s&nbsp; **%s**\n", checkbox(problem:isDone()), progressTip(problem), problem))
      end
    end
    stream:write("</details>\n\n")
  end
  stream:write("\n")
end

function outputProgress(stream, chapters)
  stream:write("# 進捗\n\n")
  for _, chapter in ipairs(chapters) do
    progressChapter(stream, chapter)
  end
end

chapters = {}
