USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE work.common.ALL;

ENTITY alu IS
    PORT (
        alu_func : IN FuncSel;
        op2 : IN word;
        result : OUT word);
END ENTITY alu;

ARCHITECTURE behavioral OF alu IS
BEGIN
    alu_proc : PROCESS (alu_func, op1, op2) IS
        VARIABLE so1, so2 : signed(31 DOWNTO 0);
        VARIABLE uo1, uo2 : unsigned(31 DOWNTO 0);
    BEGIN
        so1 := signed(op1);
        uo1 := unsigned(op1);
        CASE (alu_func) IS
            WHEN ALU_ADD => result <= std_logic_vector(so1 + so2);
            WHEN ALU_ADDU => result <= std_logic_vector(uo1 + uo2);
            WHEN ALU_SUB => result <= std_logic_vector(so1 - so2);
            WHEN ALU_SUBU => result <= std_logic_vector(uo1 - uo2);
            WHEN ALU_SLT =>
                IF so1 < so2 THEN
                    result <= "00000000000000000000000000000001";
                ELSE
                    result <= (OTHERS => '0');
                END IF;
            WHEN ALU_SLTU =>
                IF uo1 < uo2 THEN
                    result <= "00000000000000000000000000000001";
                ELSE
                    result <= (OTHERS => '0');
                END IF;
            WHEN ALU_AND => result <= op1 AND op2;
            WHEN ALU_OR => result <= op1 OR op2;
            WHEN ALU_XOR => result <= op1 XOR op2;
            WHEN ALU_SLL => result <= std_logic_vector(shift_left(uo1, to_integer(uo2(4 DOWNTO 0))));
            WHEN ALU_SRA => result <= std_logic_vector(shift_right(so1, to_integer(uo2(4 DOWNTO 0))));
            WHEN ALU_SRL => result <= std_logic_vector(shift_right(uo1, to_integer(uo2(4 DOWNTO 0))));
            WHEN OTHERS => result <= op1;
        END CASE;
    END PROCESS alu_proc;
END ARCHITECTURE behavioral;