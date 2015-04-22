# [Karotz shell](https://github.com/plumbee/kartoz-shell)



```
$ karotz.sh -h
karotz.sh -v action  [name=value]
   -v             verbose
   -s             send a stop afer this command can also be done with karotz.sh interactivemode action=stop
   -f file        save file for karotz interactive id '$HOME.karotz.key' default
   -c configfile  each line contains an instuction ( sleep n exists as additional command )
examples: 
   karotz.sh led 'action=light&color=FF0000'
   karotz.sh tts 'action=speak&lang=EN&text=this%20is%20a%20test'
see: http://dev.karotz.com/api/
````



## Copyright and license

Copyright 2015 Plumbee Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this work except in compliance with the License.
You may obtain a copy of the License in the LICENSE file, or at:

  [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

