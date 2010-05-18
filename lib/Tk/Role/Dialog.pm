use 5.010;
use strict;
use warnings;

package Tk::Role::Dialog;
# ABSTRACT: moose role for enhanced dialogs

use Moose::Role 0.92;
use MooseX::Has::Sugar;
use Tk;
use Tk::Sugar;


# -- accessors

=attr parent

The parent window of the dialog, required.

=attr title

The dialog title, default to C<tk dialog>

=attr header

A header (string) to display at the top of the window. Default to empty
string, meaning no header.

=attr resizable

A boolean to control whether the dialog can be resized or not (default).

=attr ok

A string to display as validation button label. Default to empty string,
meaning no validation button. The validation action will call
C<< $self->_valid() >>.

=attr cancel

A string to display as cancellation button label. Default to empty
string, meaning no cancellation button. The cancel action is to just
close the dialog.

=cut

has parent    => ( ro, required, weak_ref, isa=>'Tk::Widget' );
has title     => ( ro, lazy_build, isa=>'Str' );
has header    => ( ro, lazy_build, isa=>'Str' );
has resizable => ( ro, lazy_build, isa=>'Bool' );
has ok        => ( ro, lazy_build, isa=>'Str' );
has cancel    => ( ro, lazy_build, isa=>'Str' );

has _toplevel => ( rw, lazy_build, isa=>'Tk::Toplevel' );


# a hash to store the widgets for easier reference.
has _widgets => (
    ro,
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        _set_w => 'set',
        _w     => 'get',
    },
);

# -- initialization / finalization

# those are defaults for the role public attributes
sub _build_title     { 'tk dialog' }
sub _build_header    { '' }
sub _build_resizable { 0 }
sub _build_ok        { '' }
sub _build_cancel    { '' }

sub _build__toplevel {
    my $self = shift;
    return $self->parent->Toplevel;
}


#
# BUILD()
#
# called as constructor initialization
#
sub BUILD { }
after BUILD => sub {
    my $self = shift;
    $self->_build_dialog;
};



# -- gui methods

=method close

    $dialog->close;

Request to destroy the dialog.

=cut

sub close {
    my $self = shift;
    $self->_toplevel->destroy;
}


# -- private methods

#
# dialog->_build_dialog;
#
# create the various gui elements.
#
sub _build_dialog {
    my $self = shift;

    my $top = $self->_toplevel;
    $top->withdraw;

    # window title
    $top->title( $self->title );
    #$top->iconimage( pandemic_icon($top) );

    # dialog name
    if ( $self->header ) {
        my $font = $top->Font(-size=>16);
        $top->Label(
            -text => $self->header,
            -bg   => 'black',
            -fg   => 'white',
            -font => $font,
        )->pack(top, pad10, ipad10, fill2);
    }

    # build inner gui elements
    $self->_build_gui() if $self->can( '_build_gui' );

    # the dialog buttons.
    # note that we specify a bogus width in order for both buttons to be
    # the same width. since we pack them with expand set to true, their
    # width will grow - but equally. otherwise, their size would be
    # proportional to their english text.
    my $fbuttons = $top->Frame->pack(top, fillx);
    if ( $self->ok ) {
        my $but = $fbuttons->Button(
            -text    => $self->ok,
            -width   => 10,
            -command => sub { $self->_valid },
        )->pack(left, xfill2);
        $self->_set_w('ok', $but);
        $top->bind('<Return>', sub { $self->_valid });
        $top->bind('<Escape>', sub { $self->_valid }) unless $self->cancel;
    }
    if ( $self->cancel ) {
        my $but = $fbuttons->Button(
            -text    => $self->cancel,
            -width   => 10,
            -command => sub { $self->close },
        )->pack(left, xfill2);
        $self->_set_w('cancel', $but);
        $top->bind('<Escape>', sub { $self->close });
        $top->bind('<Return>', sub { $self->close }) unless $self->ok;
    }

    # center window & make it appear
    $top->Popup( -popover => $self->parent );
    if ( $self->resizable ) {
        $top->minsize($top->width, $top->height);
    } else {
        $top->resizable(0,0);
    }

    # allow dialogs to finish once everything is in place
    $self->_finish_gui if $self->can('_finish_gui');
}

no Moose::Role;
1;
__END__

=for Pod::Coverage
    BUILD
    DEMOLISH

=head1 SYNOPSIS

    package Your::Tk::Dialog::Class;

    use Moose;
    with 'Tk::Role::Dialog';

    sub _build_title     { 'window title' }
    sub _build_header    { 'big dialog header' }
    sub _build_resizable { 0 }
    sub _build_ok        { 'frobnize' }     # call $self->_valid
    sub _build_cancel    { 'close' }        # close the window

    sub _build_gui {
        # build the inner dialog widgets
    }
    sub _valid {
        # called when user clicked the 'ok' button
        $self->close;
    }


    # in your main program
    use Your::Tk::Dialog::Class;
    # create & show a new dialog
    Your::Tk::Dialog::Class->new( parent => $main_window );


=head1 DESCRIPTION

L<Tk::Role::Dialog> is meant to be used as a L<Moose> role to be
composed for easy L<Tk> dialogs creation.

It will create a new toplevel with a title, and possibly a header as
well as some buttons.

The attributes (see below) can be either defined as defaults using the
C<_build_attr()> methods, or passed arguments to the constructor call.
The only mandatory attribute is C<parent>, but you'd better provide some
other attributes if you want your dialog to be somehow usable! :-)



=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Role-Dialog>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Role-Dialog>

=item * Git repository

L<http://github.com/jquelin/tk-role-dialog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Role-Dialog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Role-Dialog>

=back

