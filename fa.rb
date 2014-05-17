#!/usr/bin/ruby -w

class FiniteAutomaton
    @@nextID = 0	# shared across all states
    attr_reader:state, :start, :final, :alphabet, :transition

    #---------------------------------------------------------------
    # Constructor for the FA
    def initialize
        @start = nil 		# start state 
        @state = { } 		# all states
        @final = { } 		# final states
        @transition = { }	# transitions
        @alphabet = [ ] 	# symbols on transitions
    end

    #---------------------------------------------------------------
    # Return number of states
    def num_states
        @state.size
    end

    #---------------------------------------------------------------
    # Creates a new state 
    def new_state
        newID = @@nextID
        @@nextID += 1
        @state[newID] = true
        @transition[newID] = {}
        newID 
    end

    #---------------------------------------------------------------
    # Creates a new state
    def add_state(v)
        unless has_state?(v)
            @state[v] = true
            @transition[v] = {}
        end
    end

    #---------------------------------------------------------------
    # Returns true if the state exists
    def has_state?(v)
        @state[v]
    end

    #---------------------------------------------------------------
    # Set (or reset) the start state
    def set_start(v)
        add_state(v)
        @start = v
    end

    #---------------------------------------------------------------
    # Set (or reset) a final state
    def set_final(v, final)
        add_state(v)
        if final
            @final[v] = true
        else
            @final.delete(v)
        end
    end

    #---------------------------------------------------------------
    # Returns true if the state is final
    def is_final?(v)
      if v.class == Array
        return @final[v[0]]
      end
      @final[v]
    end

    #---------------------------------------------------------------
    # Creates a new transition from v1 to v2 with symbol x
    # Any previous transition from v1 with symbol x is removed
    def add_transition(v1, v2, x)
        add_state(v1)
        add_state(v2)
        if get_transition(v1,x)
          @transition[v1][x].push(v2)
        else
          @transition[v1][x] = [v2]
        end
    end

    def add_transitiondfa(v1, v2, x)
        add_state(v1)
        add_state(v2)
        @transition[v1][x] = v2
    end

    #---------------------------------------------------------------
    # Get the destination state from v1 with symbol x
    # Returns nil if non-existent
    def get_transition(v1,x)
        if has_state?(v1)
            @transition[v1][x]
        else
            nil
        end
    end

    #---------------------------------------------------------------
    # Returns true if the dfa accepts the given string
    def accept?(s, current = @start)
        if s == ""
            is_final?(current)
        else
            dest = get_transition(current, s[0,1])
            if dest == nil
                false
            else
                accept?(s[1..-1], dest)
            end
        end
    end

    #---------------------------------------------------------------
    # Prints FA 
    def pretty_print
        print "% Start "
	print @start
  puts

        # Final states in sorted order
	print "% Final {"
	@final.keys.sort.each { |x| print " #{x}" }
	puts " }" 

        # States in sorted order
	print "% States {"
	@state.keys.sort.each { |x| print " #{x}" }
	puts " }" 

        # Alphabet in alphabetical order
        print "% Alphabet {"
	@alphabet.sort.each { |x| print " #{x}" }
	puts " }" 

        # Transitions in lexicographic order
        puts "% Transitions {"
	@transition.keys.sort.each { |v1| 
            @transition[v1].keys.sort.each { |x| 
                arr = get_transition(v1,x)
                puts "%  (#{v1} #{x} #{arr})" 
                
            }
        }
	puts "% }" 
    end
        
    #---------------------------------------------------------------
    # Prints FA statistics
    def print_stats
        total = 0 
        puts "FiniteAutomaton"
        puts "  #{@state.keys.length} states"
        puts "  #{@final.keys.length} final states" 
        trans = num_trans()
        trans.each_pair{|key, value| total += key*value}
        puts "  #{total} transitions"
        sorted = trans.keys.sort
        sorted.each{|key|
          puts "    #{trans[key]} states with #{key} transitions" 
        }
    end

    def num_trans()
      num = {}

      @transition.each_key{|state|
        t = 0
        @transition[state].each_key{|letter|
          if @transition[state][letter].class == Array
            t += @transition[state][letter].length
          else
            t += 1
          end
        }
        if num[t]
          num[t] += 1
        else
          num[t] = 1
        end
      }
      num
    end
    #---------------------------------------------------------------
    # accepts just symbol ("" = epsilon)
    def symbol! sym
        initialize
        s0 = new_state
        s1 = new_state
        set_start(s0)
        set_final(s1, true)
        add_transition(s0, s1, sym)
        if (sym != "") && (!@alphabet.include? sym)
            @alphabet.push sym
        end
    end

    #---------------------------------------------------------------
    # accept strings accepted by self, followed by strings accepted by newFA
    def concat! newFA
      
      @final.keys.each { |key| add_transition(key, newFA.start, "")}
      @final.keys.each { |key| set_final(key, false)}

      @transition.merge!(newFA.transition)
      @state.merge!(newFA.state)
      newFA.final.keys.each { |key| set_final(key, true)}
      
      newFA.alphabet.each{|letter|
        if !@alphabet.include?(letter)
          @alphabet.push(letter)
        end
      } 
    end

    #---------------------------------------------------------------
    # accept strings accepted by either self or newFA
    def union! newFA
  
      ustart = new_state
      uend = new_state
      
      add_transition(ustart, @start, "")
      add_transition(ustart, newFA.start, "")
      set_start(ustart)

      @transition.merge!(newFA.transition)
      @state.merge!(newFA.state)

      @final.keys.each { |key| add_transition(key, uend, "")}
      newFA.final.keys.each { |key| add_transition(key, uend, "")}

      
      @final.keys.each { |key| set_final(key, false)}
      set_final(uend, true)
      
      newFA.alphabet.each{|letter|
        if !@alphabet.include?(letter)
          @alphabet.push(letter)
        end
      } 


    end

    #---------------------------------------------------------------
    # accept any sequence of 0 or more strings accepted by self
    def closure! 
      cstart = new_state
      cend = new_state

      add_transition(cstart, cend, "")
      add_transition(cend, cstart, "")

      add_transition(cstart, @start, "")
      @final.keys.each { |key| add_transition(key, cend, "")}

      set_start(cstart)
      @final.keys.each { |key| set_final(key, false)}
      set_final(cend, true)


    end

    #---------------------------------------------------------------
    # returns DFA that accepts only strings accepted by self 
    def to_dfa
        # create a new one, or modify the current one in place,
        # and return it
        newdfa = FiniteAutomaton.new
        
        
        r = {}
        r2 ={}

        epsilonq0 = get_epsilon(@start)
        newdfa.set_start(new_state)
        r[epsilonq0] = false
        r2[epsilonq0] = newdfa.start

        while r.has_value?(false)
          r.keys.each{|key|
            if r[key] == false
              r[key] = true
              alphabet.each{|letter|
                eclose = []
                newstate = move(key, letter)
                newstate.each{|state|
                  newepsilon = get_epsilon(state)
                  eclose.concat(newepsilon)
                }
                eclose.uniq!
                if !r.has_key?(eclose) && eclose != []
                  r[eclose] = false
                  r2[eclose] = new_state
                end
                if eclose != []
                  newdfa.add_transitiondfa(r2[key], r2[eclose], letter)
                end
              }
            end
          }
        end
        r.keys.each{|key|
          key.each{|state|
            if @final.has_key?(state)
              newdfa.set_final(r2[key], true)
            end
          }
        }
        newdfa.alphabet.concat(@alphabet)
        newdfa
    end
    #--------------------------------------
    #move method for converting NFA to DFA
    def move(states, letter)
      result = []
      states.each{|state| 
        if get_transition(state, letter) != nil
          get_transition(state, letter).each{|state2| 
            if !result.include?(state2)
              result.push(state2)
            end
          }
        end
      }
      return result
    end

    #-----------------------------------------
    #Gives you the epsilon enclosure of a particular state
    def get_epsilon(start)
      epsilon = {}
      epsilon[start] = false
      
      while epsilon.has_value?(false)

        epsilon.keys.each{|key| 
          if epsilon[key] == false
            epsilon[key] = true
            if trans = get_transition(key, "")
              trans.each{|state|
                if !epsilon.has_key?(state)
                  epsilon[state] = false
                end
              }
            end
          end
          
        }
      end
      epsilon.keys
    end

    #---------------------------------------------------------------
    # returns a DFA that accepts only strings not accepted by self, 
    # and rejects all strings previously accepted by self
    def complement!
        # create a new one, or modify the current one in place,
        # and return it
        newdfa = FiniteAutomaton.new
        newdfa.set_start(@start)
        newdfa.state.merge!(@state)
        newdfa.transition.merge!(@transition)
        
        dead_state = new_state

        newdfa.state.keys.each{|key|
          if@transition[key] == {} 
   
            @alphabet.each{|letter|
              newdfa.add_transitiondfa(key, dead_state, letter)
              newdfa.add_transitiondfa(dead_state, dead_state, letter)
            }
          else
    
            @alphabet.each{|letter|
              if get_transition(key, letter) == nil
                newdfa.add_transitiondfa(key, dead_state, letter)
                newdfa.add_transitiondfa(dead_state, dead_state, letter)
              end
            }
          end
        }
        newdfa.state.each_key{|state| newdfa.set_final(state, true)}
        @final.each_key{|state| newdfa.set_final(state, false)}
        newdfa.alphabet.concat(@alphabet)
        newdfa
    end

    #---------------------------------------------------------------
    # return all strings accepted by FA with length <= strLen
    def gen_str strLen
	   sortedAlphabet = @alphabet.sort
        resultStrs = [ ] 
        testStrings = [ ]
        testStrings[0] = [] 
        testStrings[0].push ""
        1.upto(strLen.to_i) { |x|
            testStrings[x] = []
            testStrings[x-1].each { |s|
                sortedAlphabet.each { |c|
                    testStrings[x].push s+c
                }
            }
        }
        testStrings.flatten.each { |s|
            resultStrs.push s if accept? s
        }
        result = ""
        resultStrs.each { |x| result.concat '"'+x+'" ' }
        result
    end

end

#---------------------------------------------------------------
# read standard input and interpret as a stack machine

def interpreter file
   dfaStack = [ ] 
   loop do
       line = file.gets
       if line == nil then break end
       words = line.scan(/\S+/)
       words.each{ |word|
           case word
               when /DONE/
                   return
               when /SIZE/
                   f = dfaStack.last
                   puts f.num_states
               when /PRINT/
                   f = dfaStack.last
                   f.pretty_print
               when /STAT/
                   f = dfaStack.last
                   f.print_stats
               when /DFA/
                   f = dfaStack.pop
                   f2 = f.to_dfa
                   dfaStack.push f2
               when /COMPLEMENT/
                   f = dfaStack.pop
                   f2 = f.complement!
                   dfaStack.push f2
               when /GENSTR([0-9]+)/
                   f = dfaStack.last
                   puts f.gen_str($1)
               when /"([a-z]*)"/
                   f = dfaStack.last
                   str = $1
                   if f.accept?(str)
                       puts "Accept #{str}"
                   else
                       puts "Reject #{str}"
                   end
               when /([a-zE])/
                   puts "Illegal syntax for: #{word}" if word.length != 1
                   f = FiniteAutomaton.new
                   sym = $1
                   sym="" if $1=="E"
                   f.symbol!(sym)
                   dfaStack.push f
               when /\*/
                   puts "Illegal syntax for: #{word}" if word.length != 1
                   f = dfaStack.pop
                   f.closure!
                   dfaStack.push f
               when /\|/
                   puts "Illegal syntax for: #{word}" if word.length != 1
                   f1 = dfaStack.pop
                   f2 = dfaStack.pop
                   f2.union!(f1)
                   dfaStack.push f2
               when /\./
                   puts "Illegal syntax for: #{word}" if word.length != 1
                   f1 = dfaStack.pop
                   f2 = dfaStack.pop
                   f2.concat!(f1)
                   dfaStack.push f2
               else
                   puts "Ignoring #{word}"
           end
        }
   end
end

#---------------------------------------------------------------
# main( )

if false			# just debugging messages
    f = FiniteAutomaton.new
    f.set_start(1)
    f.set_final(2)
    f.set_final(3)
    f.add_transition(1,2,"a")   # need to keep this for NFA
    f.add_transition(1,3,"a")  
    f.prettyPrint
end

if ARGV.length > 0 then
  file = open(ARGV[0])
else
  file = STDIN
end

interpreter file  # type "DONE" to exit

