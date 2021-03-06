package.path = package.path .. ';../src/?.lua;src/?.lua;'
local Interpreter = require 'interpreter'

EXPORT_ASSERT_TO_GLOBALS = true
require('resources.luaunit')

TestInterpreter = {}

local compiled = {
  ['op'] = 'seq',
  ['seq'] = {
    {
      ['op'] = 'set',
      ['var'] = 'group_size',
      ['value'] = {
        ['choices'] = {['op'] = 'array', ['values'] = {1,10}},
        ['unit'] = {
          ['op'] = 'get',
          ['var'] = 'userid'
        },
        ['op'] = 'uniformChoice'
      }
    },
    {
      ['op'] = 'set',
      ['var'] = 'specific_goal',
      ['value'] = {
        ['p'] = 0.8,
        ['unit'] = {
          ['op'] = 'get',
          ['var'] = 'userid'
        },
        ['op'] = 'bernoulliTrial'
      }
    },
    {
      ['op'] = 'cond',
      ['cond'] = {
        {
          ['if'] = {
            ['op'] = 'get',
            ['var'] = 'specific_goal'
          },
          ['then'] = {
            ['op'] = 'seq',
            ['seq'] = {
              {
                ['op'] = 'set',
                ['var'] = 'ratings_per_user_goal',
                ['value'] = {
                  ['choices'] = {
                    ['op'] = 'array',
                    ['values'] = {8,16,32,64}
                  },
                  ['unit'] = {
                    ['op'] = 'get',
                    ['var'] = 'userid'
                  },
                  ['op'] = 'uniformChoice'
                }
              },
              {
                ['op'] = 'set',
                ['var'] = 'ratings_goal',
                ['value'] = {
                  ['op'] = 'product',
                  ['values'] = {
                    {
                      ['op'] = 'get',
                      ['var'] = 'group_size'
                    },
                    {
                      ['op'] = 'get',
                      ['var'] = 'ratings_per_user_goal'
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
local interpreterSalt = 'foo'

function TestInterpreter:test_works_as_intended()
  local proc = Interpreter:new(compiled, interpreterSalt, {['userid'] = 123454})
  local params = proc:getParams()
  
  assert(params['specific_goal'] == 1)
  assert(params['ratings_goal'] == 320)
end

function TestInterpreter:test_allows_overrides()
  local proc = Interpreter:new(compiled, interpreterSalt, {['userid'] = 123454})
  proc:setOverrides({['specific_goal'] = 0})
  local params = proc:getParams()
  assert(params['specific_goal'] == 0)
  assert(params['ratings_goal'] == nil)

  proc = Interpreter:new(compiled, interpreterSalt, {['userid'] = 123453})
  proc:setOverrides({['userid'] = 123454})

  assert(proc:getParams()['specific_goal'] == 1)
end
