import argparse
import re

# Creates parser and an arguement for the assembly file
parser = argparse.ArgumentParser()
parser.add_argument('assemblyFile')
args = parser.parse_args()

# Gets location of assembly file passed in
instructionsLoc = args.assemblyFile

# Opens and reads lines of assembly file into array
actualInsFile = open(instructionsLoc, "rb")
insFile = actualInsFile.readlines()

# Opens/Creates .mif file to write to
hexFile = open("instructions.mif", 'w')

# Writes initial specifications of mif file
hexFile.write("WIDTH=32;\nDEPTH=16384;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n")

# Acceptable Instructions:
accInstr = ["EQ","LT","LE","NE","ADD","AND","OR","XOR","SUB","NAND","NOR","NXOR","RSHF","LSHF","BEQ","BLT","BLE","BNE","JAL","LW","SW","ADDI","ANDI","ORI","XORI","NOT","RET","BGT","BR","GE","CALL","JMP","BGE","GT","SUBI"]

# Non-extended Instructions OPCODE Maps
normInstr = {"ADDI":"100000", "ANDI":"100100", "ORI":"100101", "XORI":"100110"}
normParenInstr = {"JAL":"001100", "LW":"010010", "SW":"011010"}
branchInstr = {"BEQ":"001000", "BLT":"001001", "BLE":"001010", "BNE":"001011"}

# Extended Instructions OPCODE Maps
extendInstr = {"EQ":"00001000", "LT":"00001001", "LE":"00001010", "NE":"00001011", "ADD":"00100000", "AND":"00100100", "OR":"00100101", "XOR":"00100110", "SUB":"00101000","NAND":"00101100", "NOR":"00101101", "NXOR":"00101110", "RSHF":"00110000", "LSHF":"00110001"}

# Pseudo Instructions
pseudoInstr = ["NOT","RET","BGT","BR","GE","CALL","JMP","BGE","GT","SUBI"]

# Register Dict
regDict = {"ZERO":0, "A0":1, "A1":2, "A2":3, "A3":4, "RV":4, "T0":5, "T1":6, "S0":7, "S1":8, "S2":9, "FP":13, "SP":14, "RA":15, "R10":10}

# Initial PC
PC = 0

# Labels Dict (Real Case Key) (Hex Values)
labels = {}

# Names Dict  (Hex Values)
names = {}

# Output to file List to 2048 words
output = 16384*[0]


# Iterate through each line of assembly file
for line in insFile:
    lineElements = line.split()

    if (lineElements):
        # Gets keyword that tells what line does
        keyword = lineElements[0]

        # Avoid Comments
        if (keyword != ";"):





            # Gets rest of line without the keyword (the operands or main info to work with)

            # Regex expression
            pattern = re.escape(keyword)+r"\s*(.*)"
            rest = re.search(pattern, line, re.I | re.U)

            operands = ""
            if (rest):
                operands = (rest.groups()[0]).strip()





            # --- Check if instruction or .ORG, .WORD, .NAME, or Label ---

            # Upper case version of keyword making it easier to decode
            keywordU = keyword.upper()

            if (keywordU == ".ORIG" or keywordU == ".ORG"):
                PC = int(operands, 16) / 4

            elif (keywordU == ".NAME"):
                vars = operands.split("=")
                names[vars[0]] = vars[1]

            elif (keywordU == ".WORD"):
                PC += 1

            elif (keywordU not in accInstr):
                # Checks if it is a Label and strips colon
                lab = keyword.strip(":")
                labels[lab] = PC

            else:
                # Just the Instructions
                PC += 1
                print

PC = 0

for line in insFile:
    oldPC = PC
    lineElements = line.split()

    if (lineElements):
        # Gets keyword that tells what line does
        keyword = lineElements[0]

        # Avoid Comments
        if (keyword != ";"):




            # Gets rest of line without the keyword (the operands or main info to work with)

            # Regex expression
            pattern = re.escape(keyword)+r"\s*(.*)"
            rest = re.search(pattern, line, re.I | re.U)

            operands = ""
            if (rest):
                operands = (rest.groups()[0]).strip()

            writtenIns = ""

            # Upper case version of keyword making it easier to decode
            keywordU = keyword.upper()

            if (keywordU == ".ORIG" or keywordU == ".ORG"):
                PC = int(operands, 16) / 4

            elif (keywordU == ".WORD"):
                if (operands in names):
                    operands = names.get(operands)
                if (operands in labels):
                    operands = labels.get(operands)

                if ("0x" in operands):
                    operands = int(operands, 16)
                output[PC] = "0x" + format(int(operands), "08x").upper()
                PC +=1

            if (keywordU in accInstr):
                PC += 1
                if (keywordU in normInstr):
                    Rs, Rt, Imm = operands.split(',')
                    Rs.strip()
                    Rt.strip()
                    Imm.strip()

                    if (Imm in labels):
                        Imm = labels.get(Imm)

                    if (Imm in names):
                        Imm = names.get(Imm)

                    ImmCheck = str(Imm)
                    if not ("0x" in ImmCheck):
                        Imm = int(Imm)
                        Imm = hex(Imm)

                    Imm = format(int(Imm, 16) % (1 << 16), "016b")
                    writtenIns = str(normInstr.get(keywordU)) + "00" + Imm + format(regDict.get(Rs.upper()),"04b") + format(regDict.get(Rt.upper()),"04b")
                    writtenIns = hex(int(writtenIns, 2))[:-1]
                    output[oldPC] = writtenIns

                elif (keywordU in normParenInstr):
                    Rt, RsImm = operands.split(',')
                    RsImm = RsImm[:-1]
                    Imm, Rs = RsImm.split('(')

                    Rt.strip()
                    Rs.strip()
                    Imm.strip()

                    if (Imm in labels):
                        Imm = labels.get(Imm) * 4
                    #     Imm = labels.get(Imm)

                    if (Imm in names):
                        Imm = names.get(Imm)

                    ImmCheck = str(Imm)
                    if not ("0x" in ImmCheck):
                        Imm = int(Imm)
                        Imm = hex(Imm)


                    inter = int(Imm, 16)
                    Imm = format(inter % (1 << 16), "016b")
                    writtenIns = str(normParenInstr.get(keywordU)) + "00" + Imm + format(regDict.get(Rs.upper()),"04b") + format(regDict.get(Rt.upper()),"04b")
                    writtenIns = hex(int(writtenIns, 2))
                    output[oldPC] = writtenIns

                elif (keywordU in branchInstr):
                    Rs, Rt, Imm = operands.split(',')

                    Rs.strip()
                    Rt.strip()
                    Imm.strip()

                    if (Imm in labels):
                        Imm = labels.get(Imm)

                    if (Imm in names):
                        Imm = names.get(Imm)

                    Imm = Imm - PC
                    ImmCheck = str(Imm)
                    if not ("0x" in ImmCheck):
                        Imm = int(Imm)
                        Imm = hex(Imm)

                    Imm = format(int(Imm, 16) % (1 << 16), "016b")
                    writtenIns = str(branchInstr.get(keywordU)) + "00" + Imm + format(regDict.get(Rs.upper()),"04b") + format(regDict.get(Rt.upper()), "04b")
                    writtenIns = hex(int(writtenIns, 2))
                    output[oldPC] = writtenIns

                elif (keywordU in extendInstr):
                    Rd, Rs, Rt = operands.split(',')
                    Rd.strip()
                    Rs.strip()
                    Rt.strip()

                    regQ = format(regDict.get(Rd.upper()), "04b")
                    regW = format(regDict.get(Rs.upper()), "04b")

                    regE = format(regDict.get(Rt.upper()), "04b")
                    writtenIns = "000000" + str(extendInstr.get(keywordU)) + "000000" +regQ+ regW+ regE
                    writtenIns = int(writtenIns, 2)
                    hexOne = "0x"+format(writtenIns, "08x")
                    output[oldPC] = hexOne

                else:
                    if (keywordU == "BR"):
                        keywordU = "BEQ"
                        operands = "Zero,Zero,"+operands
                    elif (keywordU == "NOT"):
                        keywordU = "NAND"
                        Ri, Rj = operands.split(',')
                        operands = operands + ","+Rj
                    elif (keywordU == "RET"):
                        keywordU = "JAL"
                        operands = "R10,0(RA)"
                    elif (keywordU == "BGT"):
                        keywordU = "BLT"
                        Ry,Rx,Label = operands.split(',')
                        operands=Rx+","+Ry+","+Label
                    elif (keywordU == "GE"):
                        keywordU = "LE"
                        Rz,Ry,Rx = operands.split(',')
                        operands=Rz+","+Rx+","+Ry
                    elif (keywordU == "CALL"):
                        keywordU = "JAL"
                        operands = "RA,"+operands
                    elif (keywordU == "JMP"):
                        keywordU = "JAL"
                        operands = "R10,"+operands
                    elif (keywordU == "BGE"):
                        keywordU = "BLE"
                        Ry, Rx, Label = operands.split(',')
                        operands = Rx+","+Ry+","+Label
                    elif (keywordU == "GT"):
                        keywordU = "LT"
                        Rz, Ry, Rx = operands.split(',')
                        operands = Rz + "," + Rx+","+Ry
                    elif (keywordU == "SUBI"):
                        keywordU = "ADDI"
                        Ry, Rx, Imm = operands.split(',')
                        Imm = (int(Imm) * -1)
                        operands = Ry+","+Rx+","+str(Imm)
                        print

                    if (keywordU in normInstr):
                        Rs, Rt, Imm = operands.split(',')
                        Rs.strip()
                        Rt.strip()
                        Imm.strip()

                        if (Imm in labels):
                            Imm = labels.get(Imm)

                        if (Imm in names):
                            Imm = names.get(Imm)

                        ImmCheck = str(Imm)
                        if not ("0x" in ImmCheck):
                            Imm = int(Imm)
                            Imm = hex(Imm)

                        Imm = format(int(Imm, 16) % (1 << 16), "016b")
                        writtenIns = str(normInstr.get(keywordU)) + "00" + Imm + format(regDict.get(Rs.upper()),
                                                                                        "04b") + format(
                            regDict.get(Rt.upper()), "04b")
                        writtenIns = hex(int(writtenIns, 2))[:-1]
                        output[oldPC] = writtenIns

                    elif (keywordU in normParenInstr):
                        Rt, RsImm = operands.split(',')
                        RsImm = RsImm[:-1]
                        Imm, Rs = RsImm.split('(')

                        Rt.strip()
                        Rs.strip()
                        Imm.strip()

                        if (Imm in labels):
                            Imm = labels.get(Imm)

                        if (Imm in names):
                            Imm = names.get(Imm)

                        ImmCheck = str(Imm)
                        if not ("0x" in ImmCheck):
                            Imm = int(Imm)
                            Imm = hex(Imm)

                        Imm = format(int(Imm, 16) % (1 << 16), "016b")
                        writtenIns = str(normParenInstr.get(keywordU)) + "00" + Imm + format(regDict.get(Rs.upper()),
                                                                                             "04b") + format(
                            regDict.get(Rt.upper()), "04b")
                        writtenIns = hex(int(writtenIns, 2))
                        output[oldPC] = writtenIns

                    elif (keywordU in branchInstr):
                        Rs, Rt, Imm = operands.split(',')

                        Rs.strip()
                        Rt.strip()
                        Imm.strip()

                        if (Imm in labels):
                            Imm = labels.get(Imm)

                        if (Imm in names):
                            Imm = names.get(Imm)

                        Imm = Imm - PC
                        ImmCheck = str(Imm)
                        if not ("0x" in ImmCheck):
                            Imm = int(Imm)
                            Imm = hex(Imm)

                        Imm = format(int(Imm, 16) % (1 << 16), "016b")
                        writtenIns = str(branchInstr.get(keywordU)) + "00" + Imm + format(regDict.get(Rs.upper()),
                                                                                          "04b") + format(
                            regDict.get(Rt.upper()), "04b")
                        writtenIns = hex(int(writtenIns, 2))
                        output[oldPC] = writtenIns

                    elif (keywordU in extendInstr):
                        Rd, Rs, Rt = operands.split(',')
                        Rd.strip()
                        Rs.strip()
                        Rt.strip()
                        writtenIns = "000000" + str(extendInstr.get(keywordU)) + "000000" + format(regDict.get(Rd.upper()), "04b") + format(regDict.get(Rs.upper()), "04b") + format(regDict.get(Rt.upper()), "04b")
                        writtenIns = int(writtenIns, 2)
                        hexOne = "0x" + format(writtenIns,"08x")
                        output[oldPC] = hexOne


deadStart = 0;
deadEnd = 0;
dead = 0;
for i in range(0, 16384):
    ADDRESS = format(i, "08x").upper()
    INS = str(output[i]).upper()[2:]
    if (INS):

        if (dead):
            dead = 0
            if (deadStart == deadEnd):
                hexFile.write(deadStart + " : DEAD\n")
            else:
                hexFile.write("["+deadStart + ".." + deadEnd + "] : DEAD;\n")

        hexFile.write(ADDRESS+" : "+INS+";\n")
    else:
        if (dead == 0):
            deadStart = ADDRESS
        dead = 1
        deadEnd = ADDRESS

    print

if (dead):
    dead = 0
    if (deadStart == deadEnd):
        hexFile.write(deadStart + " : DEAD\n")
    else:
        hexFile.write("[" + deadStart + ".." + deadEnd + "] : DEAD;\n")


hexFile.write("END;")
actualInsFile.close()
hexFile.close()
