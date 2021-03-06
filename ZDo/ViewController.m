//
//  ViewController.m
//  ZDToDo
//
//  Created by john song on 13-2-23.
//  Copyright (c) 2013年 john song. All rights reserved.
//

#import "ViewController.h"
#import <CoreData/CoreData.h>
#import "Record.h"
#import "ZDLoadingView.h"
#import "NoteCell.h"
#define CellHeight 50
@interface ViewController (){
    CGFloat scrollViewOffSet_y;
    NSIndexPath *selectedIndex;
    NoteCell *currentCell;
}
@property (nonatomic,strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation ViewController
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    scrollViewOffSet_y = 0;
    self.recordLogic = [RecordLogic sharedRecordLogic];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.textField = [[UITextField alloc]initWithFrame:CGRectMake(10, 10, 320, 70)];
    self.textField.font = [self.textField.font fontWithSize:26.0f];
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    self.textField.delegate = self;
    [self.textField setPlaceholder:@"准备..."];
    self.textField.hidden = YES;
    [self.view addSubview:self.textField];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma  mark UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *sections = [self.fetchedResultsController sections];
    if(sections != nil && [sections count] > 0){
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }else{
        return 0;
    }
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"NoteCell";
    NoteCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = (NoteCell *)[[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil] lastObject];
        cell.delegate = self;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
        [pan setDelegate:self];
        [cell addGestureRecognizer:pan];
    }
    Record *record = (Record*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textField.text = record.record;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return CellHeight;
}

//-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return UITableViewCellEditingStyleDelete;
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
//     Record *record = (Record*)[self.fetchedResultsController objectAtIndexPath:indexPath];
//    [self.recordLogic deleteRecord:record];
////    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
//}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UIGestureRecognizerMethod
-(void)handleSwip : (UISwipeGestureRecognizer*)recognizer{
    NoteCell *cell = [self getNoteCell:recognizer];
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [cell beginCompleteAnimation];
    }else{
        [cell beginDeleteAnimation];
    }
}

-(void)handlePan: (UIGestureRecognizer *)recognizer{
    UIPanGestureRecognizer *panRecognizer = (UIPanGestureRecognizer*)recognizer;
    CGPoint _originalLocation; // 原始位置
    CGPoint _currentLocation; // 当前位置
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        _originalLocation = [panRecognizer locationInView:self.tableView];
       _currentLocation = _originalLocation;
        currentCell = [self getNoteCell:recognizer];
    }
        else if (recognizer.state == UIGestureRecognizerStateChanged) {
//            //这部分是拖拽)
            _currentLocation = [panRecognizer locationInView:self.tableView];
            currentCell.textField.center = CGPointMake(_currentLocation.x,currentCell.textField.center.y);
            [panRecognizer setTranslation:CGPointMake(0, 0) inView:currentCell];
            } else if (recognizer.state == UIGestureRecognizerStateEnded ||
                           recognizer.state == UIGestureRecognizerStateCancelled) {
                CGSize textSize = [self.textField.text sizeWithFont:self.textField.font];
                if (currentCell.textField.frame.origin.x>=140) {
                    [currentCell beginDeleteAnimation];
                }else if (currentCell.textField.frame.origin.x<=-textSize.width+20){
                    [currentCell beginCompleteAnimation];
                }else{
                    [currentCell resetTextFieldCenter];
                }
            }
    
}

-(NoteCell*) getNoteCell : (UIGestureRecognizer*)recognizer{
    CGPoint point = [recognizer locationOfTouch:0 inView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    return (NoteCell*)[self.tableView cellForRowAtIndexPath:indexPath];
}
#pragma mark textFieldDelegate

- (void)showTextField : (NSString*)text{
    [self.textField becomeFirstResponder];
    self.textField.text = @"";
    [self.tableView setContentInset:UIEdgeInsetsMake(50, 0, 0, 0)];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField.text != nil&&![textField.text isEqualToString:@""]){
        [self.recordLogic createRecord:textField.text];
        [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
//        [self.tableView reloadData];
        
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        }];
    }
    self.textField.hidden= YES;
    [self.textField resignFirstResponder];
    return YES;
}

#pragma mark NoteCellDelegate
-(void)didSelectedNoteCell:(NoteCell *)cell{
    selectedIndex = [self.tableView indexPathForCell:cell];
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView setContentInset:UIEdgeInsetsMake(-CellHeight*selectedIndex.row, 0, 0, 0)];
    }];

}

-(void)didEndEditNoteCell:(NoteCell *)cell note:(NSString *)note{
    selectedIndex = [self.tableView indexPathForCell:cell];
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    }];
     Record *record = (Record*)[self.fetchedResultsController objectAtIndexPath:selectedIndex];
    [self.recordLogic refreshRecord:record newNote:note];

}

-(void)didEndDeleteAnimate:(NoteCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Record *record = (Record*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.recordLogic deleteRecord:record];
}

-(void)didEndCompleteAnimate:(NoteCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Record *record = (Record*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.recordLogic completeRecord:record];
}

#pragma mark scrollView Delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (self.tableView.contentOffset.y < -30 && scrollView.contentOffset.y<scrollViewOffSet_y) {
        self.textField.text = @"";
        self.textField.hidden = NO;
    }
    scrollViewOffSet_y = scrollView.contentOffset.y;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (self.tableView.contentOffset.y < -40) {
        [self showTextField:@""];
    }else{
        self.textField.hidden=  YES;
    }
}

#pragma mark - Fetched results controller
- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController == nil) {
        __fetchedResultsController = [self.recordLogic fetchedResultsController];
        __fetchedResultsController.delegate = self;
    }
    return __fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationLeft];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}



- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:{
            
         
            break;
        }
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationLeft];
            break;
    }
    
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView endUpdates];
}






@end
