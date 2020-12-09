package libbase64

import (
	"github.com/lwpyr/goscript/common"
)

func Register() {
	common.RegisterLib("base64", Lib)
}

var Lib *Base64Lib

type Base64Lib struct{}

func (b *Base64Lib) Init(tr *common.TypeRegistry) map[string]*common.Function {
	return map[string]*common.Function{
		"EncodeBase64": {
			Type: tr.FindFuncType(&common.FunctionMeta{
				In: []*common.DataType{
					common.BasicTypeMap["bytes"],
				},
				Out: []*common.DataType{
					common.BasicTypeMap["string"],
				},
			}),
			F: EncodeBase64,
		},
		"DecodeBase64": {
			Type: tr.FindFuncType(&common.FunctionMeta{
				In: []*common.DataType{
					common.BasicTypeMap["string"],
				},
				Out: []*common.DataType{
					common.BasicTypeMap["bytes"],
				},
			}),
			F: DecodeBase64,
		},
	}
}
