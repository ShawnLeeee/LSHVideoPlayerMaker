//
//  LSHVideoListVC.m
//  LSHVideoPlayerMaker
//
//  Created by lishihua on 16/3/22.
//  Copyright © 2016年 HistoryPainting. All rights reserved.
//

#import "LSHVideoListVC.h"
#import "LSHVideoPlayerVC.h"
@interface LSHVideoListVC ()

@end

@implementation LSHVideoListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(100, 200, 50, 40)];
    [button setTitle:@"Play" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(handlePush:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}
- (void)handlePush:(UIButton *)btn
{
    LSHVideoPlayerVC *vc = [[LSHVideoPlayerVC alloc] init];
    [self.navigationController pushViewController:vc animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
