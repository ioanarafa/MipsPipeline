library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test_env is
    Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR (4 downto 0);
           sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0);
           an : out STD_LOGIC_VECTOR (7 downto 0);
           cat : out STD_LOGIC_VECTOR (6 downto 0));
end test_env;

architecture Behavioral of test_env is

component MPG is
    Port ( enable : out STD_LOGIC;
           btn : in STD_LOGIC;
           clk : in STD_LOGIC);
end component;

component SSD is
    Port ( clk: in STD_LOGIC;
           digit: in STD_LOGIC_VECTOR(31 downto 0);
           an: out STD_LOGIC_VECTOR(7 downto 0);
           cat: out STD_LOGIC_VECTOR(6 downto 0));
end component;

component InstrFetch is
    Port (clk: in STD_LOGIC;
          rst : in STD_LOGIC;
          en : in STD_LOGIC;
          Branch : in STD_LOGIC_VECTOR(31 downto 0);
          JumpAddress : in STD_LOGIC_VECTOR(31 downto 0);
          Jump : in STD_LOGIC;
          PCSrc : in STD_LOGIC;
          Instruction : out STD_LOGIC_VECTOR(31 downto 0);
          PCinc : out STD_LOGIC_VECTOR(31 downto 0));
end component;

component InstrDecode
    Port ( clk: in STD_LOGIC;
           en : in STD_LOGIC;    
           Instr : in STD_LOGIC_VECTOR(25 downto 0);
           write : in STD_LOGIC_VECTOR(31 downto 0);
           RegWrite : in STD_LOGIC;
           RegDst : in STD_LOGIC;
           ExtOp : in STD_LOGIC;
           RD1 : out STD_LOGIC_VECTOR(31 downto 0);
           RD2 : out STD_LOGIC_VECTOR(31 downto 0);
           Ext_Imm : out STD_LOGIC_VECTOR(31 downto 0);
           func : out STD_LOGIC_VECTOR(5 downto 0);
           sa : out STD_LOGIC_VECTOR(10 downto 6));
end component;

component MC
    Port ( Instr : in STD_LOGIC_VECTOR(2 downto 0);
           RegDst : out STD_LOGIC;
           ExtOp : out STD_LOGIC;
           ALUSrc : out STD_LOGIC;
           Branch : out STD_LOGIC;
           Jump : out STD_LOGIC;
           ALUOp : out STD_LOGIC_VECTOR(2 downto 0);
           MemWrite : out STD_LOGIC;
           MemtoReg : out STD_LOGIC;
           RegWrite : out STD_LOGIC);
end component;

component ALU is
    Port ( PCinc : in STD_LOGIC_VECTOR(31 downto 0);
           RD1 : in STD_LOGIC_VECTOR(31 downto 0);
           RD2 : in STD_LOGIC_VECTOR(31 downto 0);
           Ext_Imm : in STD_LOGIC_VECTOR(31 downto 0);
           func : in STD_LOGIC_VECTOR(5 downto 0);
           sa : in STD_LOGIC_VECTOR(4 downto 0);
           ALUSrc : in STD_LOGIC;
           ALUOp : in STD_LOGIC_VECTOR(2 downto 0);
           BranchAddress : out STD_LOGIC_VECTOR(31 downto 0);
           ALURes : out STD_LOGIC_VECTOR(31 downto 0);
           Zero : out STD_LOGIC);
end component;

component MEM
    port ( clk : in STD_LOGIC;
           en : in STD_LOGIC;
           ALUResIn : in STD_LOGIC_VECTOR(31 downto 0);
           RD2 : in STD_LOGIC_VECTOR(31 downto 0);
           MemWrite : in STD_LOGIC;			
           MemData : out STD_LOGIC_VECTOR(31 downto 0);
           ALUResOut : out STD_LOGIC_VECTOR(31 downto 0));
end component;

signal Instr, PCinc, RD1, RD2, write, Ext_imm : STD_LOGIC_VECTOR(31 downto 0); 
signal JumpAddress, BranchAddress, ALURes, ALURes1, MemData : STD_LOGIC_VECTOR(31 downto 0);
signal func : STD_LOGIC_VECTOR(5 downto 0);
signal sa : STD_LOGIC_VECTOR(4 downto 0);
signal digit : STD_LOGIC_VECTOR(31 downto 0);
signal en, rst, PCSrc ,zero: STD_LOGIC; 
-- main controls 
signal RegDst, ExtOp, ALUSrc, Branch, Jump, MemWrite, MemtoReg, RegWrite : STD_LOGIC;
signal ALUOp :  STD_LOGIC_VECTOR(2 downto 0);

--semnale pipeline
--IF/ID
--signal en_pipe: STD_LOGIC;
signal PC_P1: STD_LOGIC_VECTOR(31 downto 0);
signal Instr_P1: STD_LOGIC_VECTOR(31 downto 0);
--signal RegID_EX: STD_LOGIC;

--ID/ EX
signal MemtoReg_P1: STD_LOGIC;
signal RegWrite_P1: STD_LOGIC;
signal MemWrite_P1: STD_LOGIC;
signal Branch_P1: STD_LOGIC;
signal ALUOp_P: STD_LOGIC_VECTOR(2 downto 0);
signal ALUSrc_P: STD_LOGIC;
signal RegDst_P: STD_LOGIC;
signal PC_P2: STD_LOGIC_VECTOR(31 downto 0);
signal RD1_P: STD_LOGIC_vector (31 downto 0); 
signal RD2_P1: STD_LOGIC_vector (31 downto 0); 
signal ExtImm_P: STD_LOGIC_vector (31 downto 0); 
signal Instr_P2: STD_LOGIC_VECTOR (9 downto 0);

--EX/MEM
signal MemtoReg_P2: STD_LOGIC;
signal RegWrite_P2: STD_LOGIC;
signal MemWrite_P: STD_LOGIC;
signal Branch_P2: STD_LOGIC;
signal BranchAddress_P: STD_LOGIC_vector (31 downto 0); 
signal Zero_P: STD_LOGIC;
signal ALURes_P1: STD_LOGIC_vector (31 downto 0); 
signal RD2_P2: STD_LOGIC_vector (31 downto 0); 

--MEM/ WB
signal MemtoReg_P3: STD_LOGIC;
signal RegWrite_P3: STD_LOGIC;
signal MemData_P: STD_LOGIC_vector (31 downto 0); 
signal ALURes_P2: STD_LOGIC_vector (31 downto 0); 


begin


    --FETCH/ID: 
    process(clk)
    begin
    if rising_edge(clk) then
         if en='1' then
    PC_P1 <= PCinc;
    Instr_P1<= Instr; --instr de la fetch
         end if;
    end if;
    end process;
  

    --ID/EX: 
    process(clk)
    begin
    
     if rising_edge(clk) then
            if en='1' then
            PC_P2<=PC_P1;
            RD1_P<=RD1;
            RD2_P2<=RD2_P1;
            ExtImm_P<=Ext_Imm;
            MemtoReg_P1 <= MemtoReg;
            RegWrite_P1 <= RegWrite;
            MemWrite_P1 <= MemWrite;
            Branch_P1 <= Branch;
            ALUSrc_P <= ALUSrc;
            ALUOp_P <= ALUOp;
            RegDst_P <= RegDst;
            end if;
       end if;
    
    end process;

    --EX/MM:
    process(clk)
    begin
      if rising_edge(clk) then
         if en = '1' then
         BranchAddress_P <= BranchAddress;
         Zero_P <= Zero;
         ALURes_P1 <= ALURes;
         RD2_P2 <= RD2_P1;
         MemtoReg_P2<= MemtoReg_P1;
         RegWrite_P2 <= RegWrite_P1;
         MemWrite_P <= MemWrite_P1;
         Branch_P2 <= Branch_P1;
         end if;
      end if;   
    end process;

    --MM/WB: 
    process(clk)
    begin
    if rising_edge(clk) then
         if en = '1' then
         MemData_P <= Memdata;
         ALURes_P2 <= ALURes1;
         MemtoReg_P3 <= MemtoReg_P2;
         RegWrite_P3 <= RegWrite_P2;  
         end if;
    end if;
    end process;


    -- buttons: reset, enable
    MPG1: MPG port map(en, btn(0), clk);
    MPG2: MPG port map(rst, btn(1), clk);
   -- MPG3: MPG port map(en, btn(2), clk); --pt butoane sa controlam la care etapa suntem
    
    -- main units
    FETCH: InstrFetch port map(clk, rst, en, BranchAddress, JumpAddress, Jump, PCSrc, Instr, PCinc);
    DECODE: InstrDecode port map(clk, en, Instr(25 downto 0), write, RegWrite, RegDst, ExtOp, RD1, RD2, Ext_imm, func, sa);
    CONTROL: MC port map(Instr(15 downto 13), RegDst, ExtOp, ALUSrc, Branch, Jump, ALUOp, MemWrite, MemtoReg, RegWrite);
    UNIT: ALU port map(PCinc, RD1, RD2, Ext_imm, func, sa, ALUSrc, ALUOp, BranchAddress, ALURes, Zero); 
    MEMORY: MEM port map(clk, en, ALURes, RD2, MemWrite, MemData, ALURes1);

    -- WB write back
    with MemtoReg select
        write <= MemData when '1',
              ALURes1 when '0',
              (others => '0') when others;

    -- branch
    PCSrc <= Zero and Branch;

    -- jump address
    JumpAddress <= PCinc(31 downto 26) & Instr(25 downto 0);

   -- SSD display MUX
    with sw(7 downto 5) select
        digit <=  Instr when "000", 
                   PCinc when "001",
                   RD1 when "010",
                   RD2 when "011",
                   Ext_Imm when "100",
                   ALURes when "101",
                   MemData when "110",
                   write when "111",
                   (others => '0') when others; 

    DISPLAY : SSD port map (clk, digit, an, cat);
    
    -- main controls
    led(10 downto 0) <= ALUOp & RegDst & ExtOp & ALUSrc & Branch & Jump & MemWrite & MemtoReg & RegWrite;
    
end Behavioral;