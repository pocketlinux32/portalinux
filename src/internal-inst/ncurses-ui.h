#include <ncurses.h>
#include <menu.h>
#include <limits.h>

struct currentMenu {
	MENU* menu;
	ITEM** items;
	int itemAmount = 0;
}

void deallocMenu(){
	free_menu(currentMenu.menu);
	for(int i = 0; i < currentMenu.itemAmount; i++){
		free_item(currentMenu.items[i]);
	}
}
