NAME = main
OBJS = $(NAME).obj

LINK_FLAG = /subsystem:windows
ML_FLAG = /c /coff

$(NAME).exe: $(OBJS)
	link $(LINK_FLAG) $(OBJS)
.asm.obj:
	ml $(ML_FLAG) $<

clean:
	del *.obj
	del *.exe