--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        features.lua
--

-- imports
import("cfeatures")
import("cxxfeatures")

-- get macro defines
function _get_macro_defines(snippets, extension, opt)

    -- make an stub source file
    local sourcefile = path.join(os.tmpdir(), "detect", "gcc_features" .. extension)
    io.writefile(sourcefile, table.concat(table.wrap(snippets), "\n"))

    -- get defines
    local results = {}
    local defines = try { function () return os.iorunv(opt.program, table.join(opt.flags or {}, {"-dM", "-E", sourcefile})) end }
    if defines then
        for _, define in ipairs(defines:split("\n")) do
            local name = define:match("#define%s+(.-)%s+")
            if name then
                results[name] = true
            end
        end
    end

    -- remove files
    os.tryrm(sourcefile)

    -- ok?
    return results
end

-- set feature with condition
function _set_feature(feature, condition)

    -- init features
    _g.features = _g.features or {}

    -- get feature kind
    local kind = feature:match("^(%w-)_")
    assert(kind, "unknown kind for the feature: %s", feature)

    -- init language extensions
    _g.extensions = _g.extensions or {c = ".c", cxx = ".cpp", objc = ".m", objcxx = ".mm"}

    -- get extension
    local extension = _g.extensions[kind]
    assert(extension, "not supported kind for the feature: %s", feature)

    -- make snippet
    local snippet = format([[
#if (%s)
#   define %s 1
#endif]], condition, feature)

    -- init features with the given extension
    local features = _g.features[extension] or {}
    _g.features[extension] = features

    -- set feature and snippet
    features[feature] = snippet
end

-- set features
function set_features(features)
    for feature, condition in pairs(features) do
        _set_feature(feature, condition)
    end
end

-- check features
function check_features(opt)

    -- check features with all extensions
    local results = {}
    for extension, features in pairs(_g.features) do

        -- make snippets
        local snippets = {}
        for _, snippet in pairs(features) do
            table.insert(snippets, snippet)
        end

        -- get defines
        local defines = _get_macro_defines(snippets, extension, opt)

        -- check features
        for feature, _ in pairs(features) do
            if defines[feature] then
                results[feature] = true
            end
        end
    end

    -- ok?
    return results
end

-- get features 
-- 
-- @param opt   the argument options, .e.g {toolname = "", program = "", programver = "", flags = {}}
--
-- @return      the features
--
function main(opt)

    -- set features for c
    set_features(cfeatures())

    -- set features for c++
    set_features(cxxfeatures())

    -- check features
    return check_features(opt)
end
