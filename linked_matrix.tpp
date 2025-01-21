/*****************************************************************************************************
 * implementation of MNode_t operations
 */
namespace linked_matrix_GJK {
template<class T>
void join_lr(MNode_t<T> *a, MNode_t<T> *b)
{   
    a->set_right(b);
    b->set_left(a);
}

template<class T>
void join_du(MNode_t<T> *a, MNode_t<T> *b)
{
    a->set_up(b);
    b->set_down(a);
}
}
