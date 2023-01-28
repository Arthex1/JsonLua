local naughty = require 'naughty' 

local _M = {} 

function _M.debug(text)
    naughty.notification({text = tostring(text)})
    
end

function _M.error(text) 
    
    
end

return _M 