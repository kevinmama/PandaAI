local U = {}

local TypeUtils = require 'klib/utils/type_utils'
U.is_table = TypeUtils.is_table
U.is_number = TypeUtils.is_number
U.is_int = TypeUtils.is_int
U.is_string = TypeUtils.is_string
U.is_native = TypeUtils.is_native

local ErrorUtils = require 'klib/utils/error_utils'
U.fail_if_missing = ErrorUtils.fail_if_missing

local TableUtils = require 'klib/utils/table_utils'
U.merge_table = TableUtils.merge_table

return U

