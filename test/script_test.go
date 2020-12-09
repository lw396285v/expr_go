package test

import (
	"fmt"
	"github.com/lwpyr/goscript"
	"github.com/lwpyr/goscript/common"
	"github.com/lwpyr/goscript/program"
	"testing"
	"time"
)

func compilePro(expr string) *program.ScriptProgram {
	ret, err := c.CompileScript(expr)
	if err != nil {
		panic(err)
	}
	return &program.ScriptProgram{Root: ret}
}

func TestA(t *testing.T) {
	setupParse()
	var expr string
	expr = `
func fib(v int64) int64 {
	if(v<2) {
		return v;
	}
	return fib(v-1)+fib(v-2);
}

print(fib(35));`
	p := compilePro(expr)
	start := time.Now()
	p.RunOnMemory(mem)
	fmt.Println(time.Since(start))
}

func TestB(t *testing.T) {
	setupParse()
	var expr string
	expr = `
num2 = 0;
for (num1=1; num1<=100; num1 = num1 + 1) {
	num2 = num2 + num1;
}
print(num2);
`
	p := compilePro(expr)
	p.RunOnMemory(mem)
}

func TestC(t *testing.T) {
	setupParse()
	var expr string
	expr = `
var sum int64 = 0;
for (local i int64 = 1; i <= 100; i++) {
	sum = sum + i;
}
print(sum);
`
	p := compilePro(expr)
	p.RunOnMemory(mem)
}

func TestD(t *testing.T) {
	setupParse()
	var expr string
	expr = `
func who(p Person) {
	if(p.name == 'Tom') {
		print('Tommy');
	} else if(p.name == 'Dave') {
		print('David');
	} else {
		print('I don\'t know');
	}
}
Tom = {name('Tom')};
who(Tom);
Tom = {name('Dave')};
who(Tom);
Tom = {name('Lisa')};
who(Tom);
`
	p := compilePro(expr)
	p.RunOnMemory(mem)
}

func TestE(t *testing.T) {
	setupParse()
	var expr string
	expr = `
var f func(int64,int64)(int64) = func(a int64, b int64) int64 {
	return a+b;
}; 
print(f(1,2));
`
	p := compilePro(expr)
	p.RunOnMemory(mem)
}

func TestF(t *testing.T) {
	setupParse()
	var expr string
	expr = `
func main(a int64, b int64) func()(int64) {
	return func()int64{
		return a+b;
	};
}

var f1 func()(int64) = main(1,2);
var f2 func()(int64) = main(3,4);
print(f1());
print(f2());
`
	p := compilePro(expr)
	p.RunOnMemory(mem)
}

func BenchmarkA(b *testing.B) {
	setupParse()
	var expr string
	expr = `
var sum int64;
sum = 0;
for (local i int64 = 1; i <= 100; i++) {
	sum = sum + i;
}
`
	p := compilePro(expr)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		p.RunOnMemory(mem)
	}
}

func setupParse() {
	// mock data
	c = goscript.NewCompiler()

	dtb := common.NewDataTypeBuilder("Person")
	dtb.SetKind(common.Message)
	dtb.SetField("name", c.FindType("string"))
	dtb.SetField("age", c.FindType("int32"))
	dtb.SetField("hobbies", c.FindSliceType("string"))

	c.AddBuiltType(dtb)

	c.AddEnum("fruits", map[string]int32{
		"apple":      int32(0),
		"banana":     int32(1),
		"orange":     int32(2),
		"strawberry": int32(3),
	})

	mem = &common.Memory{
		Data: make([]interface{}, 100),
	}

	scope := goscript.NewScope(nil)
	c.Scope = scope

	c.Include("common")
	c.Include("string")
	c.Include("json")
	c.Include("base64")
	c.Include("datetime")

	scope.AddVariable(goscript.NewVariable("Tom", c.FindType("Person")))
	scope.AddVariable(goscript.NewVariable("Jerry", c.FindType("Person")))
	scope.AddVariable(goscript.NewVariable("Friends", c.FindSliceType("Person")))
	scope.AddVariable(goscript.NewVariable("Class", c.FindMapType("int64", "Person")))
	scope.AddVariable(goscript.NewVariable("newPerson", c.FindType("Person")))
	scope.AddVariable(goscript.NewVariable("DavidId", c.FindType("int64")))
	scope.AddVariable(goscript.NewVariable("Teacher", c.FindType("Person")))
	scope.AddVariable(goscript.NewVariable("RandNumber", c.FindType("float64")))
	scope.AddVariable(goscript.NewVariable("num1", c.FindType("int64")))
	scope.AddVariable(goscript.NewVariable("num2", c.FindType("int64")))
	scope.AddVariable(goscript.NewVariable("num3", c.FindType("int64")))
	scope.AddVariable(goscript.NewVariable("num4", c.FindType("int64")))
	scope.AddVariable(goscript.NewVariable("testString", c.FindType("string")))
	scope.AddVariable(goscript.NewVariable("NewClass", c.FindMapType("int64", "Person")))
	scope.AddVariable(goscript.NewVariable("jsonObj", c.FindType("JSONObject")))
	scope.AddVariable(goscript.NewVariable("testString2", c.FindType("string")))
	scope.AddVariable(goscript.NewVariable("header", c.FindMapType("string", "string")))
	scope.AddVariable(goscript.NewVariable("fruitEnum", c.FindType("fruits")))
	scope.AddVariable(goscript.NewVariable("stringMap", c.FindMapType("string", "Person")))
	scope.AddVariable(goscript.NewVariable("float32Map", c.FindMapType("float32", "Person")))

	c.Scope = scope
}
