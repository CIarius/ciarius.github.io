"""
    # good
    board=[
    [2,9,5,7,4,3,8,6,1],
    [4,3,1,8,6,5,9,2,7],
    [8,7,6,1,9,2,5,4,3],
    [3,8,7,4,5,9,2,1,6],
    [6,1,2,3,8,7,4,9,5],
    [5,4,9,2,1,6,7,3,8],
    [7,6,3,5,2,4,1,8,9],
    [9,2,8,6,7,1,3,5,4],
    [1,5,4,9,3,8,6,7,2]
    ]
    """
    # bad
    board = [
    [1,9,5,7,4,3,8,6,2],
    [4,3,1,8,6,5,9,2,7],
    [8,7,6,1,9,2,5,4,3],
    [3,8,7,4,5,9,2,1,6],
    [6,1,2,3,8,7,4,9,5],
    [5,4,9,2,1,6,7,3,8],
    [7,6,3,5,2,4,1,8,9],
    [9,2,8,6,7,1,3,5,4],
    [2,5,4,9,3,8,6,7,1]
    ]
    
    def check(l):
        # each digit 1-9 should occur once 
        for n in range(1,10):
            try:
                l.index(n)
            except ValueError:
                return False
        return True
        
# check the rows
for row in board:
    print(check(row))
    
# check the columns
for column in [ [ board[r][c] for r in range(9) ] for c in range(9) ]:
    print(check(column))
    
# check the tiles
for tile in [[board[r][c] for r in range(row, row + 3) for c in range(col, col + 3)] for row in range(0, 9, 3) for col in range(0, 9, 3)]:
    print(check(tile))