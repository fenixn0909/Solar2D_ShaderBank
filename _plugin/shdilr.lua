
--[[
    shdilr <Shader Dealer>
    Store shader info and apply them
    ✳️ Solar2d      phoenixongogo
    
    ✅❎❇️✳️
    
    ✳️　>> Call set_comp_fill() before using Composite Shader <<
    ✳️ c_xxx: chaining call
    ✳️ the purpose of "chaning call" is only for joint multiple lines into one, make code cleaner and easier for comment out.
    
--]]


local a_val2idx = function( a_, k_ ) for i=1, #a_ do    if a_[i] == k_ then return i end   end end   --@Array Value to Index 
----------------------------------------------------------------------------------------------------
local M,m,mtFn = {},{},{}
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
local maRegi = {}
local moLast -- The last object which applied effect
local mtLastParam

-- DevTest
local maaList = {}          -- ArrayArray: List
local madShdr = {}          -- ArrayData: Shader file 
local miUN_cur = 1          -- cur mIndexUnion: ShaderData Union < Group >
local miBF_cur              -- cur mIndexBankFile

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

--=== Load file list array
M.load_list = function( kFdr_, aFN_, iU_, bKeep_ )    --@kFilePrefix, @aFileName, @iUnion, @bKeepExisting: true to append onto an already-loaded union instead of resetting it (for merging a second source folder into the same category)
    
    miBF_cur = 1;
    if not bKeep_ then
        maaList[iU_] = {}
        madShdr[iU_] = {}
    end

    local _d = {}
    local _aList, _dShdr = {},{} -- ShdrList, ShdrData
    -- ensure deterministic A-Z input (also sorted in file_get_match_sub, but keep here for safety)
    table.sort(aFN_, function(a,b) return a:lower() < b:lower() end)
    for i=1,# aFN_ do
        local _fileNm = aFN_[i]
        _d[#_d+1] = require( kFdr_ .. _fileNm )
        graphics.defineEffect(_d[#_d])
        if iU_ then
            maaList[iU_][#maaList[iU_]+1] = _fileNm
            madShdr[iU_][_fileNm] = m.extract_info( _d[#_d] )
        end
    end
    -- when merging a second source folder (ported) with bKeep, interleave globally A-Z
    if bKeep_ and maaList[iU_] then
        table.sort(maaList[iU_], function(a,b) return a:lower() < b:lower() end)
    elseif maaList[iU_] then
        -- also keep single-source lists sorted
        table.sort(maaList[iU_], function(a,b) return a:lower() < b:lower() end)
    end
end

----------------------------------------------------------------------------------------------------
-- Set & Apply
----------------------------------------------------------------------------------------------------

--=== Apply shader preset: call function which apply shader with hardcoded param
M.apply = function( kFn_, o_, t_ )  --@kShd, @oImg, @tOpt
    assert( mtFn[kFn_], "nil key: "..kFn_)
    -- assert( o_.xxx, "o_ must be image object, sprite or  group?")
    mtFn[kFn_](o_, t_)
end

--=== Apply shader universal: pass fileName, object and table with params
M.apply_U = function( self, kEff_, o_, t_ )  --@kShd, @oImg, @tOpt
    o_.fill.effect = kEff_         assert( o_.fill.effect, "nil key: "..kEff_)   
    for k,v in next, t_ do    o_.fill.effect[k] = v end
    moLast = o_
return self    end

--=== Composite Fill
M.set_comp_fill = function( o_, sPth1_, sPth2_ )
    o_.fill = { type="composite", paint1={ type="image", filename= sPth1_ }, paint2={ type="image", filename= sPth2_ } }
end

--=== Set Vertext Data
M.c_sync_param = function( self, t_ )  -- Chaining call: only call this after apply_U was called previously
    assert( moLast, "moLast is nil")
    M.sync_param( moLast, t_ )
return self    end

M.sync_param = function( o_, t_ )  --@kShd, @oImg, @tOpt
    assert( o_.fill.effect, "o_.fill.effect is nil!")
    mtLastParam = t_
    for k,v in next, t_ do    o_.fill.effect[k] = v end
end

M.sync_refresh = function( o_ )  --@kShd, @oImg, @tOpt
    -- assert( o_.fill.effect, "o_.fill.effect is nil!")
    if not mtLastParam then return    end
    if not o_.fill.effect then return    end
    local _t = mtLastParam
    for k,v in next, _t do    o_.fill.effect[k] = v end
end

--=== Set Vertext Data
M.effect_off = function( o_ )    o_.fill.effect = nil end

-------------------------------------------------------------------------------------------------
--=== Register for Tween
-------------------------------------------------------------------------------------------------

--=== Tween Register: Support M.apply_univs.  Need pass tween table ===--
M.c_regi_tween = function( self, kVD_, tEs_ )   -- Chaining call: only call this after apply_U was called previously
    assert( moLast, "moLast is nil")
    M.regi_tween( moLast, kVD_, tEs_ )
return self    end

M.regi_tween = function(  o_, kVD_, tEs_ )  --@obj, @kVertexData @tEasing
    maRegi[#maRegi+1] = { o_, kVD_, tEs_, cnt= 0, cd= #tEs_ }  --[5]:ticks
end

--=== Tween Logic
M.logic_tween = function()
    if #maRegi < 1 then    return end

    local _aR
    for i=#maRegi, 1, -1 do    --print("Called, tick: ".._aR[1])
        _aR = maRegi[i]
        _aR.cnt = _aR.cnt + 1

        M.sync_param( _aR[1], { [_aR[2]] = _aR[3][_aR.cnt] } )

        if _aR.cnt == _aR.cd then t_remove( maRegi, i) end
    end
end

-------------------------------------------------------------------------------------------------
--=== Auxiliary <Public>
-------------------------------------------------------------------------------------------------
M.end_chain = function()  moLast = nil end
M.cleanup_register = function()    maRegi = {} end
-- No specific to cleanup everything and reload them, so just cleanup the registers would be fine.


-------------------------------------------------------------------------------------------------
-- Texture Mode
----------------------------------------------------------------------------------------------------
M.set_texture_wrap = function( k_ ) -- Key: 'repeat', 'mirroredRepeat', 'clampToEdge'
    display.setDefault( "textureWrapX", k_ )
    display.setDefault( "textureWrapY", k_ )
end

-------------------------------------------------------------------------------------------------
-- Bank Setting
----------------------------------------------------------------------------------------------------
M.bank_set_union = function( i_ )    
    miUN_cur = i_ 
    M.bank_reset()
end
M.bank_reset = function()    miBF_cur = 1 end
M.bank_set_iBF = function( i_ )     assert( i_>0, "i_ must > 0")    assert( i_<= #maaList[ miUN_cur ], "i_ must <= #maaList[ miUN_cur ]")
    miBF_cur = i_
end

M.bank_set_iBF_byKey = function( k_ )
    local _iUN = a_val2idx( maaList[miUN_cur],  k_ )  assert( _iUN, "no key found: "..k_)
    miBF_cur = _iUN
end

--=== Step to next index
M.bank_next = function()
    miBF_cur = miBF_cur + 1
    if miBF_cur > #maaList[ miUN_cur ] then    miBF_cur = 1 end
end

--=== Step to previous index
M.bank_prev = function()
    miBF_cur = miBF_cur - 1
    if miBF_cur < 1 then    miBF_cur = #maaList[ miUN_cur ] end
end

----------------------------------------------------------------------------------------------------
-- Bank Data Retriving
----------------------------------------------------------------------------------------------------
M.bank_print_dbInfo = function( )
    local _d = m.get_cur_data()
    print('category: '.. _d.category) print('group: '.. _d.group) print('name: '.. _d.name)
end
M.bank_get_data = function( ) return  m.get_cur_data()    end
M.bank_get_kernal = function( ) return m.get_kernal_path( m.get_cur_data()  )    end
M.bank_get_fileName = function( ind_ ) return maaList[miUN_cur][ind_ or miBF_cur]    end
M.bank_get_textureWrap = function( ) return m.get_cur_data().textureWrap    end
M.bank_get_dVertex = function( )    if not  m.get_cur_data().vertexData then print('No VertexData Found!') return nil end
return  m.get_cur_data().vertexData    end

M.bank_get_dUniform = function( )    if not  m.get_cur_data().uniformData then print('No UniformData Found!') return nil end
return  m.get_cur_data().uniformData    end

M.new_dUniform_mat4 = function( dO_ )  --@dOrigin
    local _dO = dO_ or M.bank_get_dUniform()
    local _dN = { aName= {}, adToShdr= {}}                      -- dNew
    
    local _d
    for k=1,#_dO do
        _dN.aName[k] = _dO[k].name
        _dN.adToShdr[k] = {}
        for i=1,16 do
            _dN[#_dN+1] = {}; _d = _dN[#_dN]
            _d.name = _dO[k].paramName[i]
            _d.default = _dO[k].default[i]
            _d.min = _dO[k].min[i]
            _d.max = _dO[k].max[i]
            _d.iMat4 = k
            _d.iArr = i
            
            _dN.adToShdr[k][i] = _d.default
        end
    end

return _dN    end

-------------------------------------------------------------------------------------------------
-- Bank Apply
-------------------------------------------------------------------------------------------------
--=== Apply Shader in Bank
M.bank_apply = function( self, o_, t_ )  --@oImg, @tOpt
    if not m.get_cur_data() then print("no previous shader found!") return end
    local _k = m.get_kernal_path( m.get_cur_data() )
    M.apply_U( self, _k, o_, t_ )
return self    end


-------------------------------------------------------------------------------------------------
-- Axiliary <Private>
-------------------------------------------------------------------------------------------------
m.get_kernal_path = function( d_ ) return d_.category.. '.' ..d_.group.. '.' ..d_.name    end

m.get_cur_data = function(ind_)
    assert( madShdr[miUN_cur] [ maaList[miUN_cur] [ind_ or miBF_cur] ], "data is nil!")
return    madShdr[miUN_cur] [ maaList[miUN_cur] [ind_ or miBF_cur] ] end

m.extract_info = function( d_ )
    local _t = {}
    _t.category, _t.group, _t.name = d_.category, d_.group, d_.name
    _t.vertexData, _t.uniformData = d_.vertexData, d_.uniformData
    _t.textureWrap = d_.textureWrap or 'clampToEdge'
return _t    end

-------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
return M



