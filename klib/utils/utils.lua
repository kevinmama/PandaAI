local U = {}

local TypeUtils = require 'klib/utils/type'
U.is_table = TypeUtils.is_table
U.is_number = TypeUtils.is_number
U.is_int = TypeUtils.is_int
U.is_string = TypeUtils.is_string
U.is_native = TypeUtils.is_native

local ErrorUtils = require 'klib/utils/error_utils'
U.fail_if_missing = ErrorUtils.fail_if_missing

return U

