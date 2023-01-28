local _M = {} 
local Gio = require('lgi').require('Gio', '2.0')
local Glib = require('lgi').require('GLib', '2.0')
local gears = require 'gears'
local naughty = require 'naughty'
local misc = require 'jsonlua.misc'
local lunajson = require 'lunajson'


local function FileExists(filename)
    return gears.filesystem.file_readable(filename)
    
end 

--- @param filename string 'Complete File Path, Validated using gears.filesystem'
--- @param callback function(content) ... end 'Calls the function with a content paramter'
--- @return boolean 'The result of the operation' 
function _M.ReadAsync(filename, callback)
   
    if not FileExists(filename) then
        error("File: " .. filename .. " either does not exist, or is unreadable.")
    end
    
   
    local result = pcall(function()
        local file = Gio.File.new_for_path(filename)
        file:load_contents_async(nil, function(file_, task) 
            
            local content = Gio.File.load_contents_finish(file_, task)
            if content then
                    local result_from_callback, error_from_callback = pcall(
                        function()
                            callback(content)
                        end 
                    )
                
                    if not result_from_callback then
                       misc.debug(error_from_callback)
                    end
            else 
                    error("Error Getting Content From Filename: " .. filename)
            end
        
        end)       
    end)
        
        
    
    


    return result
end
--- @param filename string 'Complete File Path, Validated using gears.filesystem'
--- @param callback function(content) ... end 'Calls the function with the updated content and a boolean that indicates if any error occured during operation'
function _M.WriteAsync(filename, content, callback)
    local callback = callback or nil
    if not FileExists(filename) then
        error('File: ' .. filename .. " either does not exist or is unreadable.")
    end  

    _M.ReadAsync(filename, function(file_content) 
        local result, err = pcall(function()
            local file = Gio.File.new_for_path(filename)
            file:replace_contents_bytes_async(Glib.Bytes(content),nil,function(file,task,c)
                local stream = file:replace_contents_finish(task)
   
            end,0)
            
        end)
        if not result then
            misc.debug(err)
        end 
        if callback then
            local res, err = pcall(function()
                callback(content, result)
                
            end)    
            if not res then
                misc.debug(err)
            end
        end
    end)
    
end




function _M.JsonRead(filename, callback) 
    if not FileExists(filename) then
        error('File: ' .. filename .. " either does not exist or is unreadable.")
    end  

    _M.ReadAsync(filename, function(content) 
        local content_to_table = lunajson.decode(content)
        local result, error = pcall(function()
            callback(content_to_table)
        end) 
        if not result then
            misc.debug(error)
        end
    end)
    
end

function table.union(table_a, table_b) 
    local table_to_return = table_a 
    for k, v in pairs(table_b) do
        table_to_return[k] = v
    end
    return table_to_return
    
end
function _M.JsonWrite(filename, content, callback, merge_with_current_content) 
    local callback = callback or nil 
    local merge_with_current_content = merge_with_current_content or true 
    if not FileExists(filename) then
        error('File: ' .. filename .. " either does not exist or is unreadable.")
    end  
    _M.JsonRead(filename, function(file_content)
        local input = lunajson.decode(lunajson.encode(content))
        local temp_holder = input 
        if merge_with_current_content then
            temp_holder = table.union(file_content, input)
        end 
       
        _M.WriteAsync(filename, lunajson.encode(temp_holder), callback)
    end)
    
end

return _M
