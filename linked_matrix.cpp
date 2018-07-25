#include "linked_matrix.h"

// for 'DEBUG_display()'
#include <cassert>
#include <iostream>
#include <fstream>
using std::endl;

namespace linked_matrix_GJK
{

/*****************************************************************************************************
 * implementation of class LMatrix
 */
    
LMatrix::LMatrix(void) : root( new MNode0( MData() ) )
{   
    // make root->down_link constant somehow
    join_lr(root, root);
    row_count = 0;
}

LMatrix::LMatrix(bool **matrix, int m, int n) : root( new MNode0( MData() ) )
{   
    if( m == 0 || n == 0 ) {
        row_count = 0;
        return;
    }
    // create first column
    MNode0 *c = new Column(MData(), 0);
    c->data().column_id = static_cast<Column*>(c);        // point column object to itself
    join_lr(root,c);
    // create column header objects
    for(int j = 1; j < n; j++) {
        join_lr(c, new Column(MData(), 0) );
        c = c->right();
        c->data().column_id = static_cast<Column*>(c);
    }
    join_lr(c,root);
    
    // initialize m x n array of MNode0 pointers
    MNode0 ***ptr_matrix = new MNode0**[m];
    for(int k = 0; k < m; k++) {
        ptr_matrix[k] = new MNode0*[n];
    }
    
    // create nodes of LMatrix, referenced by pointers in ptr_matrix
    // also link the nodes vertically
    MNode0 *tmp;
    c = root->right();
    // j = column of matrix, i = row of matrix
    for( int j = 0; j < n; j++, c = c->right() ) {
        tmp = c;
        for(int i = 0; i < m; i++) {
            if(matrix[i][j]) {
                ptr_matrix[i][j] = new MNode0(MData(i,static_cast<Column*>(c)));
                join_du(ptr_matrix[i][j], tmp);
                tmp = ptr_matrix[i][j];
                (static_cast<Column *>(c))->add_to_size(1);
            } 
            else ptr_matrix[i][j] = NULL;
        }
        join_du(c, tmp);
    }
    
    // ignore zero rows at the bottom of the matrix
    int i;
    bool zero_row;
    for(i=m-1; i >= 0; i--) {
        zero_row = 1;
        for(int j = 0; j < n; j++) {
            if(matrix[i][j]) {
                zero_row = 0;
                break;
            }
        }
        if(!zero_row) break;
    }
    
    // 'i' is now the index of the last non-zero row, or -1 if there are no non-zero rows
    row_count = i + 1;

    
    // link the nodes horizontally
    MNode0 * first, *prev;
    // i = row, j = column
    for(; i >= 0; i--) {
        first = NULL;
        for(int j = 0; j < n; j++ ) {
            // find first non-zero matrix entry in row i,
            // and make 'first' point to the corresponding node
            if(ptr_matrix[i][j] != NULL) {
                if( first == NULL) {
                    first = ptr_matrix[i][j];
                } else {
                    join_lr(prev, ptr_matrix[i][j]);
                }
                prev = ptr_matrix[i][j];
            }
        }
        if(first != NULL) {  // if row i is not a zero row
            join_lr(prev, first);
        }
    }
    
    // finished with ptr_matrix, so now delete it
    // note this doesn't delete the nodes of the new LMatrix, just their pointers which 
    // are stored in ptr_matrix
    for(int k = 0; k < m; k++) {
        delete[] ptr_matrix[k];
    }
    delete[] ptr_matrix;
    
}

MNode0* LMatrix::head() const
{
    return root;
}

bool LMatrix::is_trivial() const
{
    return root->right() == root && root->left() == root;
}

int LMatrix::num_rows() const
{
    return row_count;
}

/*
 * Removes the row of the 'LMatrix' object containing the node pointed to by 'node'
 * Postcondition: the left, right, up, down links of nodes in the row are unchanged
 * 
 * Note: 'row_id' fields are not changed by this operation
 */
void LMatrix::remove_row(MNode0 * node)
{   
    if(node == NULL || node == root || node->data().column_id == node ) return;
    MNode0 *k = node;
    do {
        join_du( k->down(), k->up() ); 
        k->data().column_id->add_to_size(-1);
        k = k->right();
    } while( k != node ); // stop when we're back where we started
}

/*
 * Undoes the operations of 'remove_row'
 * Precondition: 'node' points to a row which has been removed via a call to 'remove_row',
 *               and neither the row nor the calling object have been altered since
 */
void LMatrix::restore_row(MNode0 * node)
{
    MNode0 *k = node;
    do {
        k->up()->set_down(k);
        k->down()->set_up(k);
        k->data().column_id->add_to_size(1);
        k = k->left();
    } while( k != node );
}


/*
 * Removes the column of the 'LMatrix' object containing the node pointed to by 'node'
 * Postcondition: the left, right, up, down links of nodes in the column are unchanged
 */
void LMatrix::remove_column(MNode0 * node)
{   
    if(node == NULL || node == root ) return;
    MNode0 *k = node;
    do {
        join_lr( k->left(), k->right() ); 
        k = k->up();
    } while( k != node ); // stop when we're back where we started
}

/*
 * Undoes the operations of 'remove_row'
 * Precondition: 'node' points to a row which has been removed via a call to 'remove_row',
 *               and neither the row nor the calling object have been altered since.
 */
void LMatrix::restore_column(MNode0 * node)
{
    MNode0 *k = node;
    do {
        k->right()->set_left(k);
        k->left()->set_right(k);
        k = k->down();
    } while( k != node );
}


LMatrix::~LMatrix()
{
    MNode0 *a, *b, *del;
    // a iterates through the column headers horizontally
    // b iterates through each column vertically
    a = root->right();
    while(a != root) {
        b = a->down();
        while(b != a) {
            del = b;
            b = b->down();
            delete del;
        }
        del = a;
        a = a->right();
        delete del;
    }
    delete root;
}



// row diagram
//  >H<>C<>C<>C<    row -1
//     >N<   >N<    row 0
//                  row 1
//        >N<>N<    row 2
// column diagram
// 0>H<0            col -1
//  >C<>N<          col 0
//  >C<      >N<    col 1
//  >C<>N<   >N<    col 2

void DEBUG_display(LMatrix& M, std::ostream& ofs)
{   
    const char l = '>';
    const char d = '<';
    const char r = '<';
    const char u = '>';
    const char H = 'H';
    const char C = 'C';
    const char N = 'N';
    const char ind = '\t';
    const char sp = ' ';
    ofs << ind << "ROW DIAGRAM" << endl << endl;
    
    ofs << ind;
    ofs << l << H << r;

    MNode0 *node = M.head()->right();
    assert( node->left() == M.head() );
    while( node != M.head() ) {
        assert( node->data().row_id == -1 );
        assert( node->right() != NULL );
        assert( node == node->right()->left() );
        ofs << l << C << r;
        node = node->right();
    }
    ofs << ind << ind << "row " << -1 << endl;
    
    int rownum = 0;
    MNode0 *colhead;
    MNode0 *prev, *first;
    while(rownum < M.num_rows() ) {
        ofs << ind << sp << sp << sp;
        colhead = M.head()->right();
        prev = NULL;
        while(colhead != M.head()) {
            node = colhead->down();
            while(node != colhead && node->data().row_id != rownum) {
                assert(node != NULL);
                assert(node->down() != NULL);
                assert(node->down()->up() == node);
                assert(node->data().column_id == colhead);
                node = node->down();
            }
            if(node == colhead) {
                ofs << sp << sp << sp;
            } else if(node->data().row_id == rownum) {
                if(prev != NULL) {
                    assert(prev->right() == node);
                    assert(node->left() == prev);
                } else {
                    first = node;
                }
                ofs << l << N << r;
                prev = node;
            }
            colhead = colhead->right();
        }
        if(prev != NULL) {
            assert(prev->right() == first);
            assert(first->left() == prev);
        }
        ofs << ind << ind << "row " << rownum << endl;
        rownum++;
    }
    
    ofs << endl << endl;
    ofs << ind << "COLUMN SIZE FIELDS" << endl << endl;
    ofs << ind;
    node = M.head()->right();
    while(node != M.head()) {
        ofs << l << static_cast<Column*>(node)->size() << r;
        node = node->right();
    }
    ofs << endl;
}


/*****************************************************************************************************
 * implementation of MNode operations
 */

template<class T>
void join_lr(MNode<T> *a, MNode<T> *b)
{
    a->set_right(b);
    b->set_left(a);
}

template<class T>
void join_du(MNode<T> *a, MNode<T> *b)
{
    a->set_up(b);
    b->set_down(a);
}


}